import 'package:dio/dio.dart';
import 'package:pharma/config/constants.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../data/models/user_model.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Sauvegarder le  token si disponible
        if (data['token'] != null) {
          await _storageService.saveToken(data['token']);
        }
        // Sauvegarder le refresh token si disponible
        if (data['refreshToken'] != null) {
          await _storageService.saveRefreshToken(data['refreshToken']);
        }

        final user = UserModel.fromJson(data['user']);
        await _storageService.saveUserData(user.toJson());
        await _storageService.saveUserId(user.uuid);

        return {
          'user': user,
          'token': data['token'],
        };
      } else {
        throw Exception('Erreur de connexion');
      }
    } catch (e) {
      throw Exception('Échec de la connexion: ${e.toString()}');
    }
  }

  // Register
  Future<bool> register({
    required String type,
    required String nom_pharmacien,
    required String email,
    required String telephone,
    required String password,
    required String nom,
    required String ville,
    required String adresse,
    String? numero,
  }) async {
    try {
      final response = await _apiService.post(
        "/${ApiEndPoints.createPharmacieEndPoint}",
        data: {
          'type':type,
          'nom_pharmacien': nom_pharmacien,
          'email': email,
          'telephone': telephone,
          'password': password,
          'nom': nom,
          'ville': ville,
          'adresse': adresse,
          if (numero != null) 'numero_autorisation': numero,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {


        return true;
      } else {
        throw Exception('Erreur d\'inscription');
      }
    } catch (e) {
      throw Exception('Échec de l\'inscription: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout(data) async {
    try {
      await _apiService.post("/${ApiEndPoints.authLogoutEndPoint}", data:data );
      await clearToken();
      await _storageService.clearAll();

    } catch (e) {
      await clearToken();
      await _storageService.clearAll();
      throw Exception('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        return UserModel.fromJson(userData);
      }



      return null;
    } catch (e) {
      return null;
    }
  }

  // Verify token
  Future<bool> verifyToken(String token) async {
    try {
      final response = await _apiService.post(
        '/auth/verify-token',
        data: {'token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Update profile
  Future<UserModel> updateProfile(Map<String, dynamic>? updateData) async {
    try {
      final response = await _apiService.post(
        "/secure/user/${updateData?['uuid']}/edit",
        data: {
          'uuid': updateData?['uuid'] ,
          'refreshToken':updateData?['refreshToken'],
          if ( updateData?['nom'] != null) 'nom_pharmacien':  updateData?['nom'],
          if (updateData?['telephone']  != null) 'telephone': updateData?['telephone'],
          if ( updateData?['email'] != null) 'email':  updateData?['email']
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201 ) {

        final user = UserModel.fromJson(response.data['data']);
        await _storageService.saveUserData(user.toJson());
        return user;
      } else {
        throw Exception('Erreur de mise à jour');
      }
    } catch (e) {
      throw Exception('Échec de la mise à jour: ${e.toString()}');
    }
  }

  // Change password
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        "/${ApiEndPoints.authEditPasswordEndPoint}",
        data: {
          'current_password': currentPassword,
          'new': newPassword,
          'email': email,
        },
      );

      return response; // Retourner la réponse
    } catch (e) {
      throw Exception('Erreur lors du changement de mot de passe: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _apiService.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: ${e.toString()}');
    }
  }

  // ========== Méthodes de gestion du token ==========

  // Sauvegarder le token
  Future<void> saveToken(String token) async {
    try {
      await _storageService.saveToken(token);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du token: ${e.toString()}');
    }
  }

  // Récupérer le token
  Future<String?> getToken() async {
    try {
      return await _storageService.getToken();
    } catch (e) {
      return null;
    }
  }

  // Supprimer le token
  Future<void> clearToken() async {
    try {
      await _storageService.clearToken();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du token: ${e.toString()}');
    }
  }

  // Rafraîchir le token (si votre API supporte cette fonctionnalité)
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken == null) {
        throw Exception('Aucun refresh token disponible');
      }

      final response = await _apiService.post(
        '/auth/refresh-token',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Sauvegarder le nouveau token
        await saveToken(data['token']);

        if (data['refresh_token'] != null) {
          await _storageService.saveRefreshToken(data['refresh_token']);
        }

        return data;
      } else {
        throw Exception('Erreur de rafraîchissement du token');
      }
    } catch (e) {
      throw Exception('Échec du rafraîchissement du token: ${e.toString()}');
    }
  }

  // Vérifier si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Optionnel: vérifier la validité du token auprès du serveur
      return await verifyToken(token);
    } catch (e) {
      return false;
    }
  }
}