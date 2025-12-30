// lib/data/providers/medicine_provider.dart
import 'package:flutter/material.dart';
import 'package:pharma/data/models/medicine_model.dart';
import 'package:pharma/repositories/medecine_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MedicineProvider extends ChangeNotifier {
  final MedicineRepository medicineRepository;

  static const String _cacheKey = 'medicines_cache';
  static const String _cacheTimeKey = 'medicines_cache_time';

  List<MedicineModel> _medicines = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isFullyLoaded = false;
  String? _errorMessage;
  DateTime? _lastLoadTime;

  // Pour la progression
  int _loadedCount = 0;
  int _totalCount = 0;

  MedicineProvider({required this.medicineRepository});

  // Getters
  List<MedicineModel> get medicines => _medicines;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isFullyLoaded => _isFullyLoaded;
  String? get errorMessage => _errorMessage;
  int get count => _medicines.length;
  int get loadedCount => _loadedCount;
  int get totalCount => _totalCount;
  double get loadingProgress => _totalCount > 0 ? _loadedCount / _totalCount : 0.0;

  /// Charger depuis le cache local
  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedTime = prefs.getString(_cacheTimeKey);

      if (cachedData != null && cachedTime != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        _medicines = jsonList.map((json) => MedicineModel.fromJson(json)).toList();
        _lastLoadTime = DateTime.parse(cachedTime);
        _isInitialized = true;
        _isFullyLoaded = true;
        _loadedCount = _medicines.length;
        _totalCount = _medicines.length;
        notifyListeners();
        debugPrint('✅ ${_medicines.length} médicaments chargés depuis le cache');
        _checkCacheAge();
      } else {
        debugPrint('ℹ️ Aucun cache trouvé');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement du cache: $e');
      if (e.toString().contains('FormatException')) {
        await clearCache();
      }
    }
  }

  /// Vérifier l'âge du cache
  void _checkCacheAge() {
    if (_lastLoadTime != null) {
      final age = DateTime.now().difference(_lastLoadTime!);
      if (age.inHours > 24) {
        debugPrint('⚠️ Cache ancien (${age.inHours}h) - Actualisation recommandée');
      }
    }
  }

  /// Sauvegarder dans le cache local
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _medicines.map((med) => med.toJson()).toList();
      final jsonString = json.encode(jsonList);

      final sizeInBytes = jsonString.length;
      final sizeInMB = sizeInBytes / (1024 * 1024);

      debugPrint('💾 Taille du cache: ${sizeInMB.toStringAsFixed(2)} MB');

      if (sizeInMB > 5) {
        debugPrint('⚠️ Cache très volumineux (${sizeInMB.toStringAsFixed(2)} MB)');
      }

      await prefs.setString(_cacheKey, jsonString);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
      debugPrint('✅ Cache sauvegardé: ${_medicines.length} médicaments');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde du cache: $e');
      if (e.toString().contains('QuotaExceededError') ||
          e.toString().contains('NSUserDefaults')) {
        debugPrint('⚠️ Limite de stockage dépassée');
      }
    }
  }

  /// Charger tous les médicaments avec pagination
  Future<void> loadAllMedicines({bool forceRefresh = false}) async {
    debugPrint('🔵 loadAllMedicines() appelé - forceRefresh: $forceRefresh');
    debugPrint('📊 État actuel: count=${_medicines.length}, isFullyLoaded=$_isFullyLoaded');

    if (_isFullyLoaded && _medicines.isNotEmpty && !forceRefresh && !isDataStale) {
      debugPrint('ℹ️ Médicaments déjà chargés et à jour (${_medicines.length} médicaments)');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _loadedCount = 0;
    _totalCount = 0;

    if (forceRefresh) {
      _medicines.clear();
      _isFullyLoaded = false;
    }

    notifyListeners();

    try {
      int currentPage = 1;
      bool hasMore = true;
      const int perPage = 100;
      List<MedicineModel> allMedicines = [];

      while (hasMore) {
        debugPrint('📥 Chargement page $currentPage...');

        final result = await medicineRepository.getMedicinesPaginated(
          page: currentPage,
          limit: perPage,
        );

        // Première page : récupérer le total
        if (currentPage == 1 && result['pagination'] != null) {
          _totalCount = result['pagination']['total'] ?? 0;
          debugPrint('📊 Total à charger: $_totalCount médicaments');
        }

        // Ajouter les nouveaux médicaments
        final List<MedicineModel> newMedicines = result['data'] ?? [];
        allMedicines.addAll(newMedicines);
        _loadedCount = allMedicines.length;

        debugPrint('✅ Page $currentPage chargée: ${newMedicines.length} médicaments (Total: $_loadedCount/$_totalCount)');

        // Mettre à jour progressivement
        _medicines = List.from(allMedicines);
        notifyListeners();

        // Vérifier s'il y a d'autres pages
        if (result['pagination'] != null) {
          hasMore = result['pagination']['has_more'] ?? false;
        } else {
          hasMore = false;
        }

        currentPage++;

        // Pause pour ne pas surcharger le serveur
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _isInitialized = true;
      _isFullyLoaded = true;
      _lastLoadTime = DateTime.now();
      _errorMessage = null;

      // Sauvegarder dans le cache
      await _saveToCache();

      debugPrint('🎉 Tous les médicaments chargés: ${_medicines.length}');

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ Erreur chargement API: $e');

      if (_medicines.isEmpty) {
        _isInitialized = false;
        _isFullyLoaded = false;
      } else {
        debugPrint('ℹ️ Utilisation des données en cache malgré l\'erreur');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pour compatibilité (appelle loadAllMedicines)
  Future<void> loadMedicines({bool forceRefresh = false}) async {
    await loadAllMedicines(forceRefresh: forceRefresh);
  }

  /// Rechercher des médicaments dans la liste locale
  List<MedicineModel> searchMedicines(String query) {
    if (query.isEmpty) {
      return _medicines;
    }

    final lowerQuery = query.toLowerCase();
    return _medicines
        .where((med) => med.nom.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Obtenir un médicament par UUID
  MedicineModel? getMedicineByUuid(String uuid) {
    try {
      return _medicines.firstWhere((med) => med.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  /// Rafraîchir les médicaments
  Future<void> refreshMedicines() async {
    debugPrint('🔄 Rafraîchissement forcé des médicaments');
    await loadAllMedicines(forceRefresh: true);
  }

  /// Vérifier si les données sont obsolètes (plus de 24h)
  bool get isDataStale {
    if (_lastLoadTime == null) return true;
    final difference = DateTime.now().difference(_lastLoadTime!);
    return difference.inHours > 24;
  }

  /// Vider le cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
      _medicines.clear();
      _isInitialized = false;
      _isFullyLoaded = false;
      _loadedCount = 0;
      _totalCount = 0;
      _lastLoadTime = null;
      notifyListeners();
      debugPrint('✅ Cache vidé');
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage du cache: $e');
    }
  }

  /// Obtenir des statistiques
  Map<String, dynamic> getStats() {
    return {
      'total': _medicines.length,
      'loadedCount': _loadedCount,
      'totalCount': _totalCount,
      'progress': '${(loadingProgress * 100).toStringAsFixed(1)}%',
      'isInitialized': _isInitialized,
      'isFullyLoaded': _isFullyLoaded,
      'isLoading': _isLoading,
      'lastLoadTime': _lastLoadTime?.toString() ?? 'Jamais',
      'isStale': isDataStale,
      'hasError': _errorMessage != null,
    };
  }
}
