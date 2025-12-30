import 'package:dio/dio.dart';
import 'package:pharma/config/constants.dart';
import '../services/storage_service.dart';
import 'interceptors.dart';

class ApiClient {
  static Dio? _dio;
  static StorageService? _storageService;

  // Initialize with StorageService
  static void init(StorageService storageService) {
    _storageService = storageService;
    // Reset dio pour forcer la recréation avec le nouveau storage service
    _dio = null;
  }

  // Create and configure Dio instance
  static Dio createDio() {
    if (_dio != null) return _dio!;

    // Ensure StorageService is initialized
    if (_storageService == null) {
      throw Exception('ApiClient must be initialized with StorageService.init() first');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.apiBaseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    // Add interceptors - IMPORTANT: passer l'instance dio à AuthInterceptor
    _dio!.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(
        storageService: _storageService!,
        dio: _dio!, // ⚠️ Passer l'instance dio
      ),
      ErrorInterceptor(),
    ]);

    return _dio!;
  }

  // Get Dio instance
  static Dio get dio {
    _dio ??= createDio();
    return _dio!;
  }

  // Close Dio instance
  static void closeDio() {
    _dio?.close(force: true);
    _dio = null;
  }

  // Reset Dio instance
  static void resetDio() {
    closeDio();
    createDio();
  }
}