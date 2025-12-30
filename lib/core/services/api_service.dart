import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pharma/config/constants.dart';
import 'package:pharma/data/models/dashboard_admin_model.dart';
import 'package:pharma/data/models/pharmacie_model.dart';
import 'package:pharma/data/models/pharmacie_widget_stats.dart';
import '../../data/models/dashboard_model.dart';
import '../network/api_client.dart';
import 'storage_service.dart';
import '../../data/models/demande_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/medicament_model.dart';
import '../../shared/enums/statut_demande.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  // ✅ Callback pour la déconnexion
  static VoidCallback? onUnauthorized;

  ApiService() {
    _dio = ApiClient.createDio();
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ajouter le token JWT
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Ajouter le refresh token dans un header custom
          final refreshToken = await _storageService.getRefreshToken();
          print("refreshToken : $refreshToken");
          if (refreshToken != null) {
            options.headers['X-Refresh-Token'] = refreshToken;
          }

          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';

          return handler.next(options);
        },

        onResponse: (response, handler) async {
          // Vérifier si le backend a rafraîchi le token automatiquement
          final tokenRefreshed = response.headers.value('x-token-refreshed');
          print("x-token-refreshed : $tokenRefreshed");
          if (tokenRefreshed == 'true') {
            final newToken = response.headers.value('x-new-token');
            final newRefreshToken = response.headers.value('x-new-refresh-token');

            if (newToken != null && newRefreshToken != null) {
              // Sauvegarder les nouveaux tokens
              await _storageService.saveToken(newToken);
              await _storageService.saveRefreshToken(newRefreshToken);

              print('✅ Token automatiquement rafraîchi par le backend');
            }
          }

          return handler.next(response);
        },

        onError: (error, handler) async {
          // Gérer les erreurs 401
          if (error.response?.statusCode == 401) {
            final data = error.response?.data;

            // ✅ Vérifier si data existe et est un Map avant d'accéder à ses propriétés
            if (data != null && data is Map) {
              final errorCode = data['code'];

              if (errorCode == 'TOKEN_EXPIRED') {
                // Token expiré et pas de refresh token fourni
                print('❌ Token expiré sans refresh token');
                await _handleLogout();
                return handler.next(error);
              }
              else if (errorCode == 'REFRESH_FAILED') {
                // Le refresh token est invalide ou expiré
                print('❌ Échec du rafraîchissement du token');
                await _handleLogout();
                return handler.next(error);
              }
            }

            // Fallback: essayer le refresh manuel (si le backend ne l'a pas fait)
            final refreshed = await _refreshTokenManually();
            if (refreshed) {
              // ✅ Retry la requête avec le nouveau token
              try {
                return handler.resolve(await _retry(error.requestOptions));
              } catch (e) {
                print('❌ Erreur lors du retry: $e');
                return handler.next(error);
              }
            } else {
              // ✅ Échec du refresh, déconnexion
              await _handleLogout();
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// ✅ Gestion de la déconnexion
  Future<void> _handleLogout() async {
    try {
      await _storageService.clearAll();
      print('🔒 Utilisateur déconnecté - redirection vers login');

      // ✅ Appeler le callback pour rediriger vers la page de connexion
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
    }
  }

  /// Refresh manuel (fallback, normalement le backend le fait)
  Future<bool> _refreshTokenManually() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        print('❌ Pas de refresh token disponible');
        return false;
      }

      print('🔄 Tentative de refresh manuel du token...');

      final response = await _dio.post(
        '/token/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _storageService.getToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Extraire les nouveaux tokens selon votre format de réponse
        final newToken = data['data']?['token'] ?? data['token'];
        final newRefreshToken = data['data']?['refreshToken'] ?? data['refreshToken'];

        if (newToken != null && newRefreshToken != null) {
          await _storageService.saveToken(newToken);
          await _storageService.saveRefreshToken(newRefreshToken);
          print('✅ Token rafraîchi manuellement');
          return true;
        }
      }
      print('❌ Réponse du refresh invalide');
      return false;
    } catch (e) {
      print('❌ Erreur refresh manuel: $e');
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    // Récupérer le nouveau token
    final newToken = await _storageService.getToken();
    final newRefreshToken = await _storageService.getRefreshToken();

    // Mettre à jour les headers
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (newToken != null) {
      headers['Authorization'] = 'Bearer $newToken';
    }
    if (newRefreshToken != null) {
      headers['X-Refresh-Token'] = newRefreshToken;
    }

    final options = Options(
      method: requestOptions.method,
      headers: headers,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // ==================== DEMANDES API ====================

  /// Get all demandes
  Future<List<DemandeModel>> getDemandes(Map<String, dynamic>? datas) async {
    try {
      print(datas);
      final response = await get(
        "${AppConstants.BASE_URL}/${ApiEndPoints.pharmacieDemandeGetEndpoint}",
        queryParameters: datas ?? {},
      );
      print("Status code: ${response.statusCode}");
      print("Response complète: ${response.data}");
      print("Data array: ${response.data['data']}");

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => DemandeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des demandes: ${e.toString()}');
    }
  }

  /// Get demandes by status
  Future<List<DemandeModel>> getDemandesByStatut(Object datas) async {
    try {
      final response = await get(
        '/demandes',
        queryParameters: {'data': datas},
      );
      final List<dynamic> data = response.data['demandes'] ?? [];
      return data.map((json) => DemandeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des demandes: ${e.toString()}');
    }
  }

  /// Get demande by ID
  Future<DemandeModel> getDemandeById(String id) async {
    try {
      final response = await get('/demandes/$id');
      return DemandeModel.fromJson(response.data['demande']);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la demande: ${e.toString()}');
    }
  }

  /// Create new demande
  Future<DemandeModel> createDemande({
    required PatientModel patient,
    required MedicamentModel medicament,
    String? notes,
  }) async {
    try {
      final response = await post(
        '/demandes',
        data: {
          'patient': patient.toJson(),
          'medicament': medicament.toJson(),
          if (notes != null) 'notes': notes,
        },
      );
      return DemandeModel.fromJson(response.data['demande']);
    } catch (e) {
      throw Exception('Erreur lors de la création de la demande: ${e.toString()}');
    }
  }

  /// Update demande status
  Future<DemandeModel> updateStatutDemande(String id, Object statut) async {
    try {
      final response = await patch(
        '/demandes/$id/statut',
        data: {'statut': statut},
      );
      return DemandeModel.fromJson(response.data['demande']);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: ${e.toString()}');
    }
  }

  /// Send notification
  Future<void> envoyerNotification(String id) async {
    try {
      await post('/demandes/$id/notify');
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification: ${e.toString()}');
    }
  }

  /// Delete demande
  Future<void> deleteDemande(String id) async {
    try {
      await delete('/demandes/$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression: ${e.toString()}');
    }
  }

  // ==================== STATISTIQUES API ====================

  /// Get general statistics
  Future<Map<String, dynamic>> getStatistiques() async {
    try {
      final response = await get('/statistiques');
      return response.data['statistiques'] ?? {};
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: ${e.toString()}');
    }
  }

  /// Get demandes per month
  Future<List<int>> getDemandesParMois() async {
    try {
      final response = await get('/statistiques/demandes-par-mois');
      final List<dynamic> data = response.data['demandesParMois'] ?? [];
      return data.map((value) => value as int).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des demandes par mois: ${e.toString()}');
    }
  }

  /// Get top medications
  Future<List<Map<String, dynamic>>> getTopMedicaments() async {
    try {
      final response = await get('/statistiques/top-medicaments');
      final List<dynamic> data = response.data['topMedicaments'] ?? [];
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des top médicaments: ${e.toString()}');
    }
  }

  /// Get statistics by period
  Future<Map<String, dynamic>> getStatistiquesByPeriode({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await get(
        '/statistiques/periode',
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      return response.data['statistiques'] ?? {};
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques par période: ${e.toString()}');
    }
  }

  // ==================== GENERIC METHODS ====================

  Future<Response> get(
      String endpoint,
      {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.get(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadFile(
      String endpoint,
      String filePath, {
        String fieldName = 'file',
        Map<String, dynamic>? additionalData,
        ProgressCallback? onSendProgress,
      }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });
      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> downloadFile(
      String endpoint,
      String savePath, {
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      final response = await _dio.download(
        endpoint,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// ✅ Gestion des erreurs corrigée
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Délai de connexion dépassé');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        // ✅ Vérification sécurisée avant d'accéder aux propriétés
        final message = (data != null && data is Map)
            ? (data['message']?.toString() ?? 'Erreur serveur')
            : 'Erreur serveur';

        switch (statusCode) {
          case 400:
            return Exception('Requête invalide: $message');
          case 401:
            return Exception('Non autorisé: $message');
          case 403:
            return Exception('Accès interdit: $message');
          case 404:
            return Exception('Ressource non trouvée: $message');
          case 500:
            return Exception('Erreur serveur interne: $message');
          default:
            return Exception(message);
        }

      case DioExceptionType.cancel:
        return Exception('Requête annulée');

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return Exception('Pas de connexion internet');
        }
        return Exception('Erreur inconnue: ${error.message}');

      default:
        return Exception('Une erreur est survenue');
    }
  }

  void cancelRequests() {
    _dio.close(force: true);
  }

  /// Get dashboard data
  Future<DashboardModel> getDashboard(Map<String, dynamic>? filters) async {
    try {
      final response = await get(
        "${AppConstants.BASE_URL}/${ApiEndPoints.dashboardEndpoint}",
        queryParameters: filters ?? {},
      );

      print("Dashboard Status code: ${response.statusCode}");
      print("Dashboard Response: ${response.data}");

      final data = response.data['data'] ?? response.data;
      return DashboardModel.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard: ${e.toString()}');
    }
  }

  /// Get dashboard admin data
  Future<DashboardAdminModel> getDashboardAdmin(Map<String, dynamic>? filters) async {
    try {
      final response = await get(
        "${AppConstants.BASE_URL}/secure/admin/dashboard",
        queryParameters: filters ?? {},
      );

      print("Dashboard Admin Status code: ${response.statusCode}");

      final data = response.data['data'] ?? response.data;
      return DashboardAdminModel.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard admin: ${e.toString()}');
    }
  }

  /// Get pharmacies stats
  Future<PharmacieWidgetStats> getPharmaciesStats(Map<String, dynamic>? filters) async {
    try {
      final response = await get(
        "${AppConstants.BASE_URL}/${ApiEndPoints.dashboardEndpoint}",
        queryParameters: filters ?? {},
      );

      final data = response.data['data'] ?? response.data;
      return PharmacieWidgetStats.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors du chargement des stats pharmacies: ${e.toString()}');
    }
  }
}