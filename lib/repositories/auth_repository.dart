import 'package:dio/dio.dart';
import 'package:pharma/data/models/user_model.dart';
import '../core/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({required AuthService authService})
      : _authService = authService;

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      print("response ${response}");
      return response['user'];
    } catch (e) {
      throw Exception('Erreur de connexion: ${e.toString()}');
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
      final response = await _authService.register(
        type: type,
        nom_pharmacien: nom_pharmacien,
        email: email,
        telephone: telephone,
        password: password,
        nom: nom,
        ville:ville,
        adresse: adresse,
        numero: numero,
      );
      print("cccccc ${response}");
      return  true;
    } catch (e) {
      throw Exception('Erreur d\'inscription: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout(data) async {
    try {
      await _authService.logout(data);
    } catch (e) {
      throw Exception('Erreur de déconnexion: ${e.toString()}');
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  // Check authentication
  Future<bool> isAuthenticated() async {
    try {
      final user = await _authService.getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Update profile
  Future<UserModel> updateProfile(Map<String, dynamic>? updateData) async {
    try {
      return await _authService.updateProfile(updateData);
    } catch (e) {
      throw Exception('Erreur de mise à jour: ${e.toString()}');
    }
  }

  // Change password
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    try {
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: email,
      );

      return response; // Retourner la réponse complète
    } catch (e) {
      throw Exception('Erreur de changement de mot de passe: ${e.toString()}');
    }
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      throw Exception('Erreur de réinitialisation: ${e.toString()}');
    }
  }
}