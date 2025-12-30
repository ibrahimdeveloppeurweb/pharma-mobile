// lib/data/providers/dashboard_provider.dart

import 'package:flutter/foundation.dart';
import 'package:pharma/data/models/dashboard_admin_model.dart';
import 'package:pharma/repositories/dashboard_repository.dart';
import '../models/dashboard_model.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardRepository _dashboardRepository;

  DashboardModel? _dashboard;
  DashboardAdminModel? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // Constructeur avec injection de dépendances
  DashboardProvider({
    required DashboardRepository dashboardRepository,
  }) : _dashboardRepository = dashboardRepository;

  // ==================== GETTERS ====================

  DashboardModel? get dashboard => _dashboard;
  DashboardAdminModel? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;

  // Getters pour les données du graphique
  GraphData? get graphData => _dashboard?.graph;
  List<MedicamentStat> get topMedicaments => _dashboard?.medicaments ?? [];
  WidgetData? get widgetStats => _dashboard?.widget;
  PrcData? get percentages => _dashboard?.prc;

  // Getters pour les statistiques
  int get totalDemandes => _dashboard?.widget.totalDemandes ?? 0;
  int get demandesEnAttente => _dashboard?.widget.enAttente ?? 0;
  int get demandesNotifiees => _dashboard?.widget.notifie ?? 0;
  int get demandesRecuperees => _dashboard?.widget.recupere ?? 0;
  int get sommeRecuperee => _dashboard?.widget.somR ?? 0;

  // ==================== MÉTHODES PRINCIPALES ====================

  /// Charger le dashboard avec filtres optionnels
  Future<void> loadDashboard({Map<String, dynamic>? filters}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _dashboard = await _dashboardRepository.getDashboard(filters: filters);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardAdmin({Map<String, dynamic>? filters}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardData = await _dashboardRepository.getDashboardAdmin(filters: filters);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: $e';
      _dashboardData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchir le dashboard
  Future<void> refreshAdmin() async {
    Map<String, dynamic>? filters;

    // Si des dates sont sélectionnées, les inclure dans les filtres
    if (_selectedStartDate != null && _selectedEndDate != null) {
      filters = {
        'date_debut': _selectedStartDate!.toIso8601String().split('T')[0],
        'date_fin': _selectedEndDate!.toIso8601String().split('T')[0],
      };
    }

    await loadDashboardAdmin(filters: filters);
  }

  /// Rafraîchir le dashboard
  Future<void> refresh() async {
    Map<String, dynamic>? filters;

    // Si des dates sont sélectionnées, les inclure dans les filtres
    if (_selectedStartDate != null && _selectedEndDate != null) {
      filters = {
        'date_debut': _selectedStartDate!.toIso8601String().split('T')[0],
        'date_fin': _selectedEndDate!.toIso8601String().split('T')[0],
      };
    }

    await loadDashboard(filters: filters);
  }

  /// Charger le dashboard par période
  Future<void> loadDashboardByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _selectedStartDate = startDate;
      _selectedEndDate = endDate;
      notifyListeners();

      _dashboard = await _dashboardRepository.getDashboardByPeriod(
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

  /// Charger le dashboard d'aujourd'hui
  Future<void> loadToday() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      final today = DateTime.now();
      _selectedStartDate = DateTime(today.year, today.month, today.day);
      _selectedEndDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
      notifyListeners();

      _dashboard = await _dashboardRepository.getDashboardToday();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger le dashboard de cette semaine
  Future<void> loadThisWeek() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      final today = DateTime.now();
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      _selectedStartDate = startOfWeek;
      _selectedEndDate = endOfWeek;
      notifyListeners();

      _dashboard = await _dashboardRepository.getDashboardByWeek(today);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger le dashboard de ce mois
  Future<void> loadThisMonth() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      final today = DateTime.now();
      final firstDay = DateTime(today.year, today.month, 1);
      final lastDay = DateTime(today.year, today.month + 1, 0);
      _selectedStartDate = firstDay;
      _selectedEndDate = lastDay;
      notifyListeners();

      _dashboard = await _dashboardRepository.getDashboardByMonth(
        today.year,
        today.month,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger un mois spécifique
  Future<void> loadMonth(int year, int month) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);
      _selectedStartDate = firstDay;
      _selectedEndDate = lastDay;
      notifyListeners();

      _dashboard = await _dashboardRepository.getDashboardByMonth(year, month);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Réinitialiser les filtres de date
  void clearDateFilters() {
    _selectedStartDate = null;
    _selectedEndDate = null;
    notifyListeners();
  }

  /// Effacer l'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Effacer les données du dashboard
  void clearDashboard() {
    _dashboard = null;
    notifyListeners();
  }
}