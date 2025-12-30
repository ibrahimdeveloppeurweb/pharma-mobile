import 'package:flutter/foundation.dart';
import 'package:pharma/repositories/stats_repository.dart';


class StatsProvider with ChangeNotifier {
  final StatsRepository _statsRepository = StatsRepository();

  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _monthlyStats = [];
  List<Map<String, dynamic>> _topMedicaments = [];
  Map<String, int> _statusDistribution = {};
  double _recoveryRate = 0.0;
  double _averageWaitingTime = 0.0;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get monthlyStats => _monthlyStats;
  List<Map<String, dynamic>> get topMedicaments => _topMedicaments;
  Map<String, int> get statusDistribution => _statusDistribution;
  double get recoveryRate => _recoveryRate;
  double get averageWaitingTime => _averageWaitingTime;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Dashboard stats getters
  int get totalDemandes => _dashboardStats['total_demandes'] ?? 0;
  int get enAttente => _dashboardStats['en_attente'] ?? 0;
  int get alertesEnvoyees => _dashboardStats['alertes_envoyees'] ?? 0;
  int get recuperes => _dashboardStats['recuperes'] ?? 0;

  // Load dashboard stats
  Future<void> loadDashboardStats() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _dashboardStats = await _statsRepository.getDashboardStats();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load monthly stats
  Future<void> loadMonthlyStats({int? year}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final currentYear = year ?? DateTime.now().year;
      _monthlyStats = await _statsRepository.getMonthlyStats(year: currentYear);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load top medicaments
  Future<void> loadTopMedicaments({int limit = 10}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _topMedicaments = await _statsRepository.getMostRequestedMedicaments(
        limit: limit,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load recovery rate
  Future<void> loadRecoveryRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _recoveryRate = await _statsRepository.getRecoveryRate(
        startDate: startDate,
        endDate: endDate,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load average waiting time
  Future<void> loadAverageWaitingTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _averageWaitingTime = await _statsRepository.getAverageWaitingTime(
        startDate: startDate,
        endDate: endDate,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load status distribution
  Future<void> loadStatusDistribution({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _statusDistribution = await _statsRepository.getStatusDistribution(
        startDate: startDate,
        endDate: endDate,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all statistics
  Future<void> loadAllStats() async {
    await Future.wait([
      loadDashboardStats(),
      loadMonthlyStats(),
      loadTopMedicaments(),
      loadRecoveryRate(),
      loadAverageWaitingTime(),
      loadStatusDistribution(),
    ]);
  }

  // Export statistics
  Future<String?> exportStats({
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final downloadUrl = await _statsRepository.exportStats(
        format: format,
        startDate: startDate,
        endDate: endDate,
      );

      _isLoading = false;
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh all stats
  Future<void> refresh() async {
    await loadAllStats();
  }

  // Get monthly data for chart
  List<double> getMonthlyChartData() {
    final data = List<double>.filled(12, 0.0);
    for (final stat in _monthlyStats) {
      final month = stat['month'] as int;
      final count = (stat['count'] as num).toDouble();
      if (month >= 1 && month <= 12) {
        data[month - 1] = count;
      }
    }
    return data;
  }

  // Get status labels and values for pie chart
  Map<String, double> getStatusChartData() {
    final data = <String, double>{};
    _statusDistribution.forEach((key, value) {
      data[key] = value.toDouble();
    });
    return data;
  }
}