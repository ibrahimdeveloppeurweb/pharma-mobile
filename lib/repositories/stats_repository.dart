import '../../core/services/api_service.dart';

class StatsRepository {
  final ApiService _apiService = ApiService();

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.get('/stats/dashboard');

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw Exception('Erreur de chargement des statistiques: ${e.toString()}');
    }
  }

  // Get demandes statistics
  Future<Map<String, dynamic>> getDemandesStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/stats/demandes',
        queryParameters: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw Exception('Erreur de chargement: ${e.toString()}');
    }
  }

  // Get monthly statistics
  Future<List<Map<String, dynamic>>> getMonthlyStats({
    required int year,
  }) async {
    try {
      final response = await _apiService.get(
        '/stats/monthly',
        queryParameters: {'year': year},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'];
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Erreur de chargement: ${e.toString()}');
    }
  }

  // Get most requested medicaments
  Future<List<Map<String, dynamic>>> getMostRequestedMedicaments({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/stats/medicaments/most-requested',
        queryParameters: {
          'limit': limit,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'];
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Erreur de chargement: ${e.toString()}');
    }
  }

  // Get recovery rate
  Future<double> getRecoveryRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/stats/recovery-rate',
        queryParameters: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return (response.data['rate'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Get average waiting time
  Future<double> getAverageWaitingTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/stats/average-waiting-time',
        queryParameters: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return (response.data['average_days'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Get status distribution
  Future<Map<String, int>> getStatusDistribution({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/stats/status-distribution',
        queryParameters: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return Map<String, int>.from(response.data);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final response = await _apiService.get('/stats/performance');

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Export statistics
  Future<String?> exportStats({
    required String format, // 'pdf', 'excel', 'csv'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/stats/export',
        queryParameters: {
          'format': format,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return response.data['download_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}