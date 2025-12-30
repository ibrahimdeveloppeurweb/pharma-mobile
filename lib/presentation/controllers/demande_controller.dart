import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../data/models/demande_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/medicament_model.dart';
import '../../shared/enums/statut_demande.dart';

class DemandeController extends ChangeNotifier {
  final ApiService _apiService;

  List<DemandeModel> _demandes = [];
  DemandeModel? _selectedDemande;
  bool _isLoading = false;
  String? _errorMessage;

  DemandeController({required ApiService apiService})
      : _apiService = apiService;

  List<DemandeModel> get demandes => _demandes;
  DemandeModel? get selectedDemande => _selectedDemande;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger toutes les demandes
  Future<void> loadDemandes( Map<String, dynamic>?  data) async {
    _setLoading(true);
    _clearError();

    try {
      _demandes = await _apiService.getDemandes(data);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Charger les demandes filtrées par statut
  Future<void> loadDemandesByStatut(Object data) async {
    _setLoading(true);
    _clearError();

    try {
      _demandes = await _apiService.getDemandesByStatut(data);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Charger une demande par ID
  Future<void> getDemandeById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedDemande = await _apiService.getDemandeById(id);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Créer une nouvelle demande
  Future<bool> createDemande({
    required PatientModel patient,
    required MedicamentModel medicament,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newDemande = await _apiService.createDemande(
        patient: patient,
        medicament: medicament,
        notes: notes,
      );

      _demandes.insert(0, newDemande);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Mettre à jour le statut d'une demande
  Future<bool> updateStatutDemande(String id, StatutDemande newStatut) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedDemande =
      await _apiService.updateStatutDemande(id, newStatut);

      // Mettre à jour dans la liste
      final index = _demandes.indexWhere((d) => d.id == id);
      if (index != -1) {
        _demandes[index] = updatedDemande;
      }

      // Mettre à jour la demande sélectionnée
      if (_selectedDemande?.id == id) {
        _selectedDemande = updatedDemande;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Envoyer une notification de disponibilité
  Future<bool> envoyerNotificationDisponible(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.envoyerNotification(id);

      // Mettre à jour le statut à "notifie"
      await updateStatutDemande(id, StatutDemande.notifie);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Annuler une demande
  Future<bool> annulerDemande(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.deleteDemande(id);

      // Supprimer de la liste
      _demandes.removeWhere((d) => d.id == id);

      // Supprimer la demande sélectionnée si c'est celle-ci
      if (_selectedDemande?.id == id) {
        _selectedDemande = null;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Rechercher des demandes
  List<DemandeModel> searchDemandes(String query) {
    if (query.isEmpty) return _demandes;

    return _demandes.where((demande) {
      final patientName = demande.patient.nomComplet.toLowerCase();
      final medicamentName = demande.medicament.nom.toLowerCase();
      final telephone = demande.patient.telephone;
      final searchQuery = query.toLowerCase();

      return patientName.contains(searchQuery) ||
          medicamentName.contains(searchQuery) ||
          telephone.contains(searchQuery);
    }).toList();
  }

  /// Filtrer par statut
  List<DemandeModel> filterByStatut(StatutDemande statut) {
    return _demandes.where((demande) => demande.statut == statut).toList();
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