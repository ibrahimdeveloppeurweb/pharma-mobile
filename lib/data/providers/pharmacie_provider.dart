// lib/data/providers/pharmacie_provider.dart
import 'package:flutter/foundation.dart';
import 'package:pharma/data/models/pharmacie_model.dart';
import 'package:pharma/data/models/pharmacie_widget_stats.dart';
import '../../repositories/pharmacie_repository.dart';


class PharmacieProvider with ChangeNotifier {
  final PharmacieRepository _pharmacieRepository = PharmacieRepository();

  PharmacieWidgetStats? _widgetStats;
  List<PharmacieModel> _pharmacies = [];
  List<PharmacieModel> _pharmaciesStats = []; // Pour les stats du dashboard
  List<String> _villes = [];
  PharmacieModel? _selectedPharmacie;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  PharmacieWidgetStats? get widgetStats => _widgetStats;
  List<PharmacieModel> get pharmacies => _pharmacies;
  List<PharmacieModel> get pharmaciesStats => _pharmaciesStats;
  List<String> get villes => _villes;
  PharmacieModel? get selectedPharmacie => _selectedPharmacie;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Widget stats getters
  int get totalPharmacies => _widgetStats?.totalPharmacies ?? 0;
  int get pharmaciesActives => _widgetStats?.pharmaciesActives ?? 0;
  int get totalDemandes => _widgetStats?.totalDemandes ?? 0;
  int get notificationsTotal => _widgetStats?.notificationsTotal ?? 0;
  double get tauxActivite => _widgetStats?.tauxActivite ?? 0.0;

  // Load pharmacies stats (pour dashboard admin)
  Future<void> loadPharmaciesStats(Map<String, dynamic>? filters) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _pharmacieRepository.getPharmaciesStats(filters);

      print("object ${response}");

      // Charger les stats du widget
      if (response.containsKey('widget')) {
        _widgetStats = PharmacieWidgetStats.fromJson(response['widget']);
      }

      // Charger la liste des pharmacies avec stats
      if (response.containsKey('pharmacies')) {
        final List<dynamic> pharmaciesData = response['pharmacies'];
        _pharmaciesStats = pharmaciesData
            .map((item) => PharmacieModel.fromStatsJson(item))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load pharmacies (liste complète)
  Future<void> loadPharmacies(Map<String, dynamic>? filters) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _pharmacies = await _pharmacieRepository.getPharmacies(filters);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load pharmacie by ID
  Future<void> loadPharmacieById(int id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _selectedPharmacie = await _pharmacieRepository.getPharmacieById(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create pharmacie
  Future<bool> createPharmacie(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final newPharmacie = await _pharmacieRepository.createPharmacie(data);

      if (newPharmacie != null) {
        _pharmacies.insert(0, newPharmacie);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void notifyPharmacieCreated() {
    notifyListeners();
  }

  void notifyPharmacieUpdated() {
    notifyListeners();
  }

  // Update pharmacie
  Future<bool> updatePharmacie(String? uuid, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners(); // 🔥 NOTIFIER AVANT

      final updatedPharmacie = await _pharmacieRepository.updatePharmacie(uuid!, data);

      if (updatedPharmacie != null) {
        final index = _pharmacies.indexWhere((p) => p.uuid == uuid);
        if (index != -1) {
          _pharmacies[index] = updatedPharmacie;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete pharmacie
  Future<bool> deletePharmacie( String? uuid, int? id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _pharmacieRepository.deletePharmacie(uuid);

      if (success) {
        _pharmacies.removeWhere((p) => p.id == id);
        if (_selectedPharmacie?.id == id) {
          _selectedPharmacie = null;
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle pharmacie status
  Future<bool> togglePharmacieStatus(int id, bool actif) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _pharmacieRepository.togglePharmacieStatus(
        id,
        actif,
      );

      if (success) {
        final index = _pharmacies.indexWhere((p) => p.id == id);
        if (index != -1) {
          // Recharger la pharmacie pour avoir les données à jour
          await loadPharmacieById(id);
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load villes
  Future<void> loadVilles() async {
    try {
      _villes = await _pharmacieRepository.getVilles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // // Refresh all data
  // Future<void> refresh() async {
  //   await Future.wait([
  //     loadPharmaciesStats(),
  //     loadPharmacies(),
  //     loadVilles(),
  //   ]);
  // }

  // Clear selected pharmacie
  void clearSelectedPharmacie() {
    _selectedPharmacie = null;
    notifyListeners();
  }

  // Get pharmacies actives only
  List<PharmacieModel> get pharmaciesActivesList {
    return _pharmacies.where((p) => p.actif == true).toList();
  }

  // Get pharmacies par ville
  List<PharmacieModel> getPharmaciesByVille(String ville) {
    return _pharmacies.where((p) => p.ville == ville).toList();
  }

  // Search pharmacies
  List<PharmacieModel> searchPharmacies(String query) {
    final lowerQuery = query.toLowerCase();
    return _pharmacies.where((p) {
      return p.nom.toLowerCase().contains(lowerQuery) ||
          p.ville.toLowerCase().contains(lowerQuery) ||
          (p.adresse?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}