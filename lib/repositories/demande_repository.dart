import 'package:pharma/config/constants.dart';

import '../core/services/api_service.dart';
import '../data/models/demande_model.dart';

class DemandeRepository {
  final ApiService _apiService;

  DemandeRepository({required ApiService apiService})
      : _apiService = apiService;

  /// Get all demandes
  Future<List<DemandeModel>> getAllDemandes() async {
    try {
      final response = await _apiService.get('/demandes');
      final List<dynamic> data = response.data['demandes'] ?? [];
      return data.map((json) => DemandeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des demandes: ${e.toString()}');
    }
  }

  /// Get demande by ID
  Future<DemandeModel> getDemandeById(String uuid) async {
    try {
      final response = await _apiService.get(  "/${ApiEndPoints.pharmacieDemandeGetEndpoint}/${uuid}");
      return DemandeModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la demande: ${e.toString()}');
    }
  }

  /// Create new demande
  Future<DemandeModel> createDemande({
    required String nom_patient,
    required String telephone_patient,
    required List<Map<String, dynamic>> medicaments,
    required String modePaiement,
  }) async {
    try {
      final response = await _apiService.post(
        "/${ApiEndPoints.createpharmacieDemandeGetEndpoint}",
        data: {
          'nom_patient': nom_patient,
          'telephone_patient': telephone_patient,
          'medicaments': medicaments,
          'mode_paiement': modePaiement

        },
      );
      print("response.data  ${response.data['data']}");
      return DemandeModel.fromJson(response.data['data']);
    } catch (e) {

     print( e);
      throw Exception('Erreur lors de la création de la demande: ${e.toString()}');
    }
  }

  /// Send alert to patient
  /// Send alert to patient
  Future<DemandeModel> sendAlert(String uuid) async {
    try {
      final response = await _apiService.post(
          "/${ApiEndPoints.pharmacieDemandeGetEndpoint}/${uuid}/notifier"
      );

      // Vérifier si c'est une erreur (status: bad_request ou code: 422)
      if (response.data != null) {
        final data = response.data;

        // Si c'est une erreur
        if (data['status'] == 'bad_request' || data['code'] == 422 || data['data'] == null) {
          String errorMessage = 'Erreur lors de l\'envoi de l\'alerte';

          errorMessage = data['message'].toString();

          throw Exception(errorMessage);
        }

        // Si succès, retourner la demande
        if (data['data'] != null) {
          return DemandeModel.fromJson(data['data']);
        }
      }

      throw Exception('Réponse invalide du serveur');

    } catch (e) {
      // Si l'exception vient déjà de nous, la relancer
      if (e is Exception && e.toString().startsWith('Exception:')) {
        rethrow;
      }

      // Sinon, extraire le message depuis l'erreur string
      String errorMessage = 'Erreur lors de l\'envoi de l\'alerte';

      final errorStr = e.toString();
      if (errorStr.contains('msg: ')) {
        final msgStart = errorStr.indexOf('msg: ') + 5;
        final afterMsg = errorStr.substring(msgStart);
        final msgEnd = afterMsg.indexOf(', ');

        if (msgEnd > 0) {
          errorMessage = afterMsg.substring(0, msgEnd).trim();
        } else {
          errorMessage = afterMsg.split('}')[0].trim();
        }
      }

      throw Exception(errorMessage);
    }
  }

  /// Mark demande as recovered
  Future<DemandeModel> markAsRecovered(String uuid) async {
    try {
      final response = await _apiService.post(
          "/${ApiEndPoints.pharmacieDemandeGetEndpoint}/${uuid}/recuperee"
      );

      // Vérifier si c'est une erreur (status: bad_request ou code: 422)
      if (response.data != null) {
        final data = response.data;

        // Si succès, retourner la demande
        if (data['data'] != null) {
          return DemandeModel.fromJson(data['data']);
        }
      }

      throw Exception('Réponse invalide du serveur');

    } catch (e) {
      // Si l'exception vient déjà de nous, la relancer
      if (e is Exception && e.toString().startsWith('Exception:')) {
        rethrow;
      }

      // Sinon, extraire le message depuis l'erreur string
      String errorMessage = 'Erreur lors de l\'envoi de l\'alerte';

      final errorStr = e.toString();
      if (errorStr.contains('msg: ')) {
        final msgStart = errorStr.indexOf('msg: ') + 5;
        final afterMsg = errorStr.substring(msgStart);
        final msgEnd = afterMsg.indexOf(', ');

        if (msgEnd > 0) {
          errorMessage = afterMsg.substring(0, msgEnd).trim();
        } else {
          errorMessage = afterMsg.split('}')[0].trim();
        }
      }

      throw Exception(errorMessage);
    }
  }


  /// Cancel demande
  Future<DemandeModel> cancelDemande(String id) async {
    try {
      final response = await _apiService.patch('/demandes/$id/cancel');
      return DemandeModel.fromJson(response.data['demande']);
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: ${e.toString()}');
    }
  }

  /// Delete demande
  Future<bool> deleteDemande(String id) async {
    try {
      await _apiService.delete('/demandes/$id');
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: ${e.toString()}');
    }
  }

  /// Search demandes
  Future<List<DemandeModel>> searchDemandes(String query) async {
    try {
      final response = await _apiService.get(
        '/demandes/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data['demandes'] ?? [];
      return data.map((json) => DemandeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: ${e.toString()}');
    }
  }

  /// Get demandes by status
  Future<List<DemandeModel>> getDemandesByStatut(String statut) async {
    try {
      final response = await _apiService.get(
        '/demandes',
        queryParameters: {'statut': statut},
      );
      final List<dynamic> data = response.data['demandes'] ?? [];
      return data.map((json) => DemandeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des demandes: ${e.toString()}');
    }
  }

  /// OPTIMISÉ : Get demandes et statistiques en un seul appel
  Future<Map<String, dynamic>> getDemandesWithStatistiques(Map<String, dynamic>?  data) async {
    try {
      final response = await _apiService.get(
        "/${ApiEndPoints.pharmacieDemandeStatsGetEndpoint}",
         queryParameters: data ?? {},
      );

      // Extraire les demandes
      final List<dynamic> demandesData = response.data['data']['demandes'] ?? [];
      print("demandesData ${demandesData}" );
      final List<DemandeModel> demandes = demandesData
          .map((json) => DemandeModel.fromJson(json))
          .toList();

      // Extraire les statistiques
      final Map<String, dynamic> widgetData = response.data['data']['widget'] ?? {};
      final Map<String, int> statistiques = {
        'total': widgetData['total'] ?? 0,
        'en_attente': widgetData['en_attente'] ?? 0,
        'notifie': widgetData['notifie'] ?? 0,
        'recupere': widgetData['recupere'] ?? 0,
      };

      return {
        'demandes': demandes,
        'statistiques': statistiques,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement: ${e.toString()}');
    }
  }
}