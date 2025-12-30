import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../core/services/storage_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController({
    required AuthService authService,
    required StorageService storageService,
  })  : _authService = authService,
        _storageService = storageService;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Connexion
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      _currentUser = response['user'];
      final token = response['token'];

      // Sauvegarder le token
      await _storageService.saveToken(token);
      await _storageService.saveUser(_currentUser!);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Inscription
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
    _setLoading(true);
    _clearError();

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
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout(data) async {
    _setLoading(true);

    try {
      await _authService.logout(data);
      await _storageService.clearToken();
      await _storageService.clearUser();

      _currentUser = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> checkAuthStatus() async {
    _setLoading(true);

    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        _setLoading(false);
        return false;
      }

      // Récupérer l'utilisateur stocké
      final user = await _storageService.getUser();

      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }

      // Vérifier le token auprès du serveur
      final isValid = await _authService.verifyToken(token);

      if (isValid) {
        final userData = await _authService.getCurrentUser();
        _currentUser = userData;
        await _storageService.saveUser(_currentUser!);
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }


  /// Changer le mot de passe
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
          email:email
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Réinitialiser le mot de passe
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}