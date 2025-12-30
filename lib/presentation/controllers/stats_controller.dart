import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class StatsController extends ChangeNotifier {
  final ApiService _apiService;

  Map<String, dynamic>? _statistiques;
  List<int>? _demandesParMois;
  List<Map<String, dynamic>>? _topMedicaments;
  bool _isLoading = false;
  String? _errorMessage;

  StatsController({required ApiService apiService})
      : _apiService = apiService;

  Map<String, dynamic>? get statistiques => _statistiques;
  List<int>? get demandesParMois => _demandesParMois;
  List<Map<String, dynamic>>? get topMedicaments => _topMedicaments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger toutes les statistiques
  Future<void> loadStatistiques() async {
    _setLoading(true);
    _clearError();

    try {
      _statistiques = await _apiService.getStatistiques();
      _demandesParMois = await _apiService.getDemandesParMois();
      _topMedicaments = await _apiService.getTopMedicaments();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Obtenir le taux de récupération
  double get tauxRecuperation {
    if (_statistiques == null) return 0.0;

    final total = _statistiques!['totalDemandes'] ?? 0;
    final recuperes = _statistiques!['recuperes'] ?? 0;

    if (total == 0) return 0.0;
    return (recuperes / total * 100);
  }

  /// Obtenir le délai moyen
  double get delaiMoyen {
    if (_statistiques == null) return 0.0;
    return _statistiques!['delaiMoyen']?.toDouble() ?? 0.0;
  }

  /// Obtenir les statistiques par période
  Future<Map<String, dynamic>> getStatistiquesByPeriode({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final stats = await _apiService.getStatistiquesByPeriode(
        startDate: startDate,
        endDate: endDate,
      );

      _setLoading(false);
      return stats;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return {};
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