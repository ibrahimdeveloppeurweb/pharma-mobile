import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pharma/config/constants.dart';
import '../services/storage_service.dart';

// Logging Interceptor - Log all requests and responses
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────────────');
      print('│ REQUEST');
      print('├─────────────────────────────────────────────────────────────');
      print('│ Method: ${options.method}');
      print('│ URL: ${options.uri}');
      print('│ Headers: ${options.headers}');
      if (options.data != null) {
        print('│ Body: ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        print('│ Query Parameters: ${options.queryParameters}');
      }
      print('└─────────────────────────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────────────');
      print('│ RESPONSE');
      print('├─────────────────────────────────────────────────────────────');
      print('│ Status Code: ${response.statusCode}');
      print('│ Data: ${response.data}');
      print('└─────────────────────────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────────────');
      print('│ ERROR');
      print('├─────────────────────────────────────────────────────────────');
      print('│ ${err.message}');
      if (err.response != null) {
        print('│ Status Code: ${err.response?.statusCode}');
        print('│ Data: ${err.response?.data}');
      }
      print('└─────────────────────────────────────────────────────────────');
    }
    handler.next(err);
  }
}

// Auth Interceptor - Add authentication token to requests
class AuthInterceptor extends Interceptor {
  final StorageService storageService;
  final Dio dio;

  AuthInterceptor({
    required this.storageService,
    required this.dio,
  });

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // Skip auth for login and register endpoints
    final isAuthEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh');

    if (!isAuthEndpoint) {
      final token = await storageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - Token expired
    if (err.response?.statusCode == 401) {
      // Éviter les boucles infinies de refresh
      if (err.requestOptions.path.contains('/auth/refresh')) {
        await storageService.clearAll();
        return handler.next(err);
      }

      final requestOptions = err.requestOptions;

      // Try to refresh token
      final refreshed = await _refreshToken();

      if (refreshed) {
        // Retry the request with new token
        final token = await storageService.getToken();
        if (token != null && token.isNotEmpty) {
          requestOptions.headers['Authorization'] = 'Bearer $token';

          try {
            // Utiliser la même instance Dio avec tous les intercepteurs
            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        }
      }

      // Refresh failed - logout user
      await storageService.clearAll();
      return handler.next(err);
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        if (kDebugMode) {
          print('❌ No refresh token available');
        }
        return false;
      }

      // Créer une instance Dio séparée SANS intercepteurs pour le refresh
      final refreshDio = Dio(BaseOptions(
        baseUrl: '${AppConstants.apiBaseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      if (kDebugMode) {
        print('🔄 Attempting to refresh token...');
      }

      final response = await refreshDio.post(
        ApiEndPoints.authTokenRefreshEndPoint,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'refreshToken': refreshToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map &&
            data.containsKey('token') &&
            data.containsKey('refreshToken')) {

          final newToken = data['token'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;

          if (newToken != null &&
              newToken.isNotEmpty &&
              newRefreshToken != null &&
              newRefreshToken.isNotEmpty) {

            await storageService.saveToken(newToken);
            await storageService.saveRefreshToken(newRefreshToken);

            if (kDebugMode) {
              print('✅ Token refreshed successfully');
            }
            return true;
          }
        }

        if (kDebugMode) {
          print('❌ Invalid refresh response format: $data');
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token refresh failed: $e');
      }
      return false;
    }
  }
}

// Error Interceptor - Handle and format errors
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Délai de connexion dépassé';
        break;

      case DioExceptionType.sendTimeout:
        errorMessage = 'Délai d\'envoi dépassé';
        break;

      case DioExceptionType.receiveTimeout:
        errorMessage = 'Délai de réception dépassé';
        break;

      case DioExceptionType.badResponse:
        errorMessage = _handleStatusCode(err.response?.statusCode);

        // Try to get error message from response
        if (err.response?.data is Map) {
          final data = err.response?.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'] as String;
          } else if (data.containsKey('error')) {
            errorMessage = data['error'] as String;
          }
        }
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Requête annulée';
        break;

      case DioExceptionType.badCertificate:
        errorMessage = 'Certificat SSL invalide';
        break;

      case DioExceptionType.connectionError:
        errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet';
        break;

      case DioExceptionType.unknown:
        if (err.error.toString().contains('SocketException')) {
          errorMessage = 'Pas de connexion internet';
        } else {
          errorMessage = 'Une erreur inconnue est survenue';
        }
        break;

      default:
        errorMessage = 'Une erreur est survenue';
    }

    // Create a custom DioException with formatted message
    final customError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
    );

    handler.next(customError);
  }

  String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide';
      case 401:
        return 'Non autorisé. Veuillez vous connecter';
      case 403:
        return 'Accès interdit';
      case 404:
        return 'Ressource non trouvée';
      case 405:
        return 'Méthode non autorisée';
      case 408:
        return 'Délai de requête dépassé';
      case 409:
        return 'Conflit de données';
      case 422:
        return 'Données invalides';
      case 429:
        return 'Trop de requêtes. Veuillez réessayer plus tard';
      case 500:
        return 'Erreur serveur interne';
      case 502:
        return 'Passerelle incorrecte';
      case 503:
        return 'Service temporairement indisponible';
      case 504:
        return 'Délai de passerelle dépassé';
      default:
        return 'Erreur serveur ($statusCode)';
    }
  }
}

// Retry Interceptor - Retry failed requests
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetry = _shouldRetry(err);

    if (!shouldRetry) {
      return handler.next(err);
    }

    int retryCount = 0;
    final extra = err.requestOptions.extra;
    if (extra.containsKey('retry_count')) {
      retryCount = extra['retry_count'] as int;
    }

    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    retryCount++;
    err.requestOptions.extra['retry_count'] = retryCount;

    if (kDebugMode) {
      print('Retrying request... Attempt $retryCount of $maxRetries');
    }

    await Future.delayed(retryDelay * retryCount);

    try {
      final response = await Dio().fetch(err.requestOptions);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on specific status codes
    if (err.response?.statusCode != null) {
      final statusCode = err.response!.statusCode!;
      return statusCode >= 500 || statusCode == 408 || statusCode == 429;
    }

    return false;
  }
}

// Cache Interceptor - Cache GET requests
class CacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};
  final Duration cacheDuration;

  CacheInterceptor({
    this.cacheDuration = const Duration(minutes: 5),
  });

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final cacheKey = _getCacheKey(options);
    final cachedEntry = _cache[cacheKey];

    if (cachedEntry != null && !cachedEntry.isExpired) {
      if (kDebugMode) {
        print('Returning cached response for: ${options.uri}');
      }
      return handler.resolve(cachedEntry.response);
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Only cache successful GET requests
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200) {
      final cacheKey = _getCacheKey(response.requestOptions);
      _cache[cacheKey] = CacheEntry(
        response: response,
        timestamp: DateTime.now(),
        duration: cacheDuration,
      );
    }

    handler.next(response);
  }

  String _getCacheKey(RequestOptions options) {
    return '${options.uri}${options.queryParameters}';
  }

  void clearCache() {
    _cache.clear();
  }

  void removeCacheEntry(String url) {
    _cache.remove(url);
  }
}

// Cache Entry Model
class CacheEntry {
  final Response response;
  final DateTime timestamp;
  final Duration duration;

  CacheEntry({
    required this.response,
    required this.timestamp,
    required this.duration,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > duration;
  }
}