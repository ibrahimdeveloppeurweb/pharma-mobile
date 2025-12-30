import 'package:flutter/material.dart';
import 'package:pharma/data/models/user_model.dart';
import '../../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check authentication status
  Future<bool> checkAuthStatus() async {
    try {
      final isAuth = await _authRepository.isAuthenticated();

      if (isAuth) {
        // Get current user
        final user = await _authRepository.getCurrentUser();

        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;
          notifyListeners();
          return true;
        } else {
          _isAuthenticated = false;
          return false;
        }
      } else {
        _isAuthenticated = false;
        return false;
      }
    } catch (e) {
      _isAuthenticated = false;
      return false;
    }
  }

  /// Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authRepository.login(
        email: email,
        password: password,
      );
      print("_currentUser ${_currentUser}");
      _isAuthenticated = true;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_formatErrorMessage(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  /// Register
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
      final response = await _authRepository.register(
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

      _isAuthenticated = true;
      _setLoading(false);
      notifyListeners();
      return response;
    } catch (e) {
      _setError(_formatErrorMessage(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  /// Logout
  Future<void> logout(data) async {
    _setLoading(true);

    try {
      await _authRepository.logout(data);
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _isLoading = false;

    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      // ✅ IMPORTANT : Nettoyer les données du provider
      // même si l'API échoue
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _isLoading = false;
      _setLoading(false);
      // ✅ Notifier tous les listeners
      notifyListeners();

      debugPrint('✅ AuthProvider nettoyé');
    }



  }

  /// Update profile
  Future<bool> updateProfile(Map<String, dynamic>? updateData) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authRepository.updateProfile(updateData);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_formatErrorMessage(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  /// Change password
  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword, String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authRepository.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
          email: email
      );

      // Accéder au code de réponse HTTP
      final statusCode = response.statusCode;
      print('Code de réponse: $statusCode');
      final data = response.data['data'] ?? response.data;
      // Ou traiter selon le code
      if (statusCode == 200 || statusCode == 201) {
        _setLoading(false);
        return true;
      } else {
        final data = response.data['data'] ?? response.data;
        print(response);
        _setError(data['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(_formatErrorMessage(e.toString()));
      _setLoading(false);
      return false;
    }
  }
  /// Forgot password
  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.forgotPassword(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_formatErrorMessage(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail
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

  String _formatErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    return error;
  }

  /// Clear all data
  void clear() {
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}