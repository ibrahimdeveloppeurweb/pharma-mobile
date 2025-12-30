import 'package:flutter/foundation.dart';
import 'package:pharma/repositories/demande_repository.dart';
import 'package:pharma/repositories/medicament_repository.dart';
import 'package:pharma/repositories/patient_repository.dart';
import '../models/demande_model.dart';
import '../../shared/enums/statut_demande.dart';

class DemandeProvider with ChangeNotifier {
  final DemandeRepository _demandeRepository;
  final PatientRepository _patientRepository;
  final MedicamentRepository _medicamentRepository;

  List<DemandeModel> _demandes = [];
  DemandeModel? _selectedDemande;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = 'tous'; // tous, en_attente, notifie, termine

  // Constructeur avec injection de dépendances
  DemandeProvider({
    required DemandeRepository demandeRepository,
    required PatientRepository patientRepository,
    required MedicamentRepository medicamentRepository,
  })  : _demandeRepository = demandeRepository,
        _patientRepository = patientRepository,
        _medicamentRepository = medicamentRepository;

  // Getters
  List<DemandeModel> get demandes => _demandes;
  DemandeModel? get selectedDemande => _selectedDemande;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  // Ajoutez la variable pour les statistiques
  Map<String, int> _statistiques = {
    'total': 0,
    'en_attente': 0,
    'notifie': 0,
    'recupere': 0,
  };

// Ajoutez le getter
  Map<String, int> get statistiques => _statistiques;







  // Load all demandes
  Future<void> loadDemandes() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _demandes = await _demandeRepository.getAllDemandes();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load demande by ID
  Future<void> loadDemandeById(String uuid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _selectedDemande = await _demandeRepository.getDemandeById(uuid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alias pour compatibilité avec les écrans
  Future<void> getDemandeById(String id) async {
    await loadDemandeById(id);
  }

  // Create demande
  Future<bool> createDemande({
    required String nom_patient,
    required String telephone_patient,
    required List<Map<String, dynamic>> medicaments,
    required String modePaiement,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create demande
      final demande = await _demandeRepository.createDemande(
        nom_patient: nom_patient,
        telephone_patient: telephone_patient,
        medicaments: medicaments,
        modePaiement: modePaiement,
      );

      _demandes.insert(0, demande);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Send alert (Envoyer notification)
  Future<bool> sendAlert(String uuid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedDemande = await _demandeRepository.sendAlert(uuid);

      // Update in list
      final index = _demandes.indexWhere((d) => d.uuid == uuid);
      if (index != -1) {
        _demandes[index] = updatedDemande;
      }

      // Update selected if needed
      if (_selectedDemande?.id == uuid) {
        _selectedDemande = updatedDemande;
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Alias pour compatibilité avec les écrans
  Future<bool> envoyerNotificationDisponible(String id) async {
    return await sendAlert(id);
  }

  // Update statut
  Future<bool> updateStatutDemande(String id, StatutDemande newStatut) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Appeler le repository approprié selon le statut
      DemandeModel updatedDemande;
      if (newStatut == StatutDemande.recupere) {
        updatedDemande = await _demandeRepository.markAsRecovered(id);
      } else if (newStatut == StatutDemande.notifie) {
        updatedDemande = await _demandeRepository.sendAlert(id);
      } else {
        throw Exception('Statut non supporté');
      }

      // Update in list
      final index = _demandes.indexWhere((d) => d.id == id);
      if (index != -1) {
        _demandes[index] = updatedDemande;
      }

      // Update selected if needed
      if (_selectedDemande?.id == id) {
        _selectedDemande = updatedDemande;
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mark as recovered
  Future<bool> markAsRecovered(String uuid) async {
    return await updateStatutDemande(uuid, StatutDemande.recupere);
  }

  // Cancel demande
  Future<bool> cancelDemande(String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedDemande = await _demandeRepository.cancelDemande(id);

      // Update in list
      final index = _demandes.indexWhere((d) => d.id == id);
      if (index != -1) {
        _demandes[index] = updatedDemande;
      }

      // Update selected if needed
      if (_selectedDemande?.id == id) {
        _selectedDemande = updatedDemande;
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Alias pour compatibilité
  Future<bool> annulerDemande(String id) async {
    return await cancelDemande(id);
  }

  // Delete demande
  Future<bool> deleteDemande(String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _demandeRepository.deleteDemande(id);

      if (success) {
        _demandes.removeWhere((d) => d.id == id);
        if (_selectedDemande?.id == id) {
          _selectedDemande = null;
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

  // Search demandes
  Future<void> searchDemandes(String query) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (query.isEmpty) {
        await loadDemandes();
      } else {
        _demandes = await _demandeRepository.searchDemandes(query);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load statistiques (pour compatibilité)
  Future<void> loadStatistiques(Map<String, dynamic>?  data) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Récupérer demandes ET statistiques en un seul appel
      final result = await _demandeRepository.getDemandesWithStatistiques(data);
      _demandes = result['demandes'] as List<DemandeModel>;
      _statistiques = result['statistiques'] as Map<String, int>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear selected demande
  void clearSelected() {
    _selectedDemande = null;
    notifyListeners();
  }

  // Refresh
  Future<void> refresh() async {
    await loadDemandes();
  }
}