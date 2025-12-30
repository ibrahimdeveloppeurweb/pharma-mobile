import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../data/models/dashboard_model.dart';

class DashboardController extends ChangeNotifier {
  final ApiService _apiService;

  DashboardModel? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardController({required ApiService apiService})
      : _apiService = apiService;

  DashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger les données du dashboard
  Future<void> loadDashboard({Map<String, dynamic>? filters}) async {
    _setLoading(true);
    _clearError();

    try {
      _dashboard = await _apiService.getDashboard(filters);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Rafraîchir les données du dashboard
  Future<void> refreshDashboard({Map<String, dynamic>? filters}) async {
    await loadDashboard(filters: filters);
  }

  /// Obtenir les données du graphique
  GraphData? get graphData => _dashboard?.graph;

  /// Obtenir les médicaments les plus demandés
  List<MedicamentStat> get topMedicaments => _dashboard?.medicaments ?? [];

  /// Obtenir les statistiques des widgets
  WidgetData? get widgetStats => _dashboard?.widget;

  /// Obtenir les pourcentages
  PrcData? get percentages => _dashboard?.prc;

  /// Obtenir le nombre total de demandes
  int get totalDemandes => _dashboard?.widget.totalDemandes ?? 0;

  /// Obtenir le nombre de demandes en attente
  int get demandesEnAttente => _dashboard?.widget.enAttente ?? 0;

  /// Obtenir le nombre de demandes notifiées
  int get demandesNotifiees => _dashboard?.widget.notifie ?? 0;

  /// Obtenir le nombre de demandes récupérées
  int get demandesRecuperees => _dashboard?.widget.recupere ?? 0;

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

  @override
  void dispose() {
    super.dispose();
  }
}