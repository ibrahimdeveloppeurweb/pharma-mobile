import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

class StorageService {
  SharedPreferences? _prefs;

  // Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get SharedPreferences instance
  Future<SharedPreferences> get _instance async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  // Token Management
  Future<bool> saveToken(String token) async {
    final prefs = await _instance;
    return prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await _instance;
    return prefs.getString('auth_token');
  }

  Future<bool> clearToken() async {
    final prefs = await _instance;
    return prefs.remove('auth_token');
  }

  // Refresh Token
  Future<bool> saveRefreshToken(String refreshToken) async {
    final prefs = await _instance;
    return prefs.setString('refresh_token', refreshToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _instance;
    return prefs.getString('refresh_token');
  }

  // User Management
  Future<bool> saveUser(UserModel user) async {
    final prefs = await _instance;
    return prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await _instance;
    final data = prefs.getString('user_data');
    if (data != null) {
      try {
        return UserModel.fromJson(jsonDecode(data));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> clearUser() async {
    final prefs = await _instance;
    return prefs.remove('user_data');
  }

  // User ID
  Future<bool> saveUserId(String userId) async {
    final prefs = await _instance;
    return prefs.setString('user_id', userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _instance;
    return prefs.getString('user_id');
  }

  // User Data (legacy - for backward compatibility)
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await _instance;
    return prefs.setString('user_data_json', jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _instance;
    final data = prefs.getString('user_data_json');
    if (data != null) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Clear all data
  Future<bool> clearAll() async {
    final prefs = await _instance;
    return prefs.clear();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Save multiple values at once
  Future<bool> saveAuthData({
    required String token,
    required String refreshToken,
    required UserModel user,
  }) async {
    try {
      await saveToken(token);
      await saveRefreshToken(refreshToken);
      await saveUser(user);
      await saveUserId(user.uuid);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear all auth data
  Future<bool> clearAuthData() async {
    try {
      await clearToken();
      await clearUser();
      return true;
    } catch (e) {
      return false;
    }
  }
}