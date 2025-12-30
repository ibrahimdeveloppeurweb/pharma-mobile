import '../core/services/api_service.dart';
import '../data/models/patient_model.dart';

class PatientRepository {
  final ApiService _apiService;

  PatientRepository({required ApiService apiService})
      : _apiService = apiService;

  /// Get or create patient
  Future<PatientModel> getOrCreatePatient({
    required String nomComplet,
    required String telephone,
    String? email,
  }) async {
    try {
      // First try to find existing patient by phone
      final searchResponse = await _apiService.get(
        '/patients/search',
        queryParameters: {'telephone': telephone},
      );

      if (searchResponse.data['patients'] != null &&
          (searchResponse.data['patients'] as List).isNotEmpty) {
        return PatientModel.fromJson(searchResponse.data['patients'][0]);
      }

      // If not found, create new patient
      final response = await _apiService.post(
        '/patients',
        data: {
          'nom_complet': nomComplet,
          'telephone': telephone,
          if (email != null) 'email': email,
        },
      );
      return PatientModel.fromJson(response.data['patient']);
    } catch (e) {
      throw Exception('Erreur patient: ${e.toString()}');
    }
  }

  /// Get all patients
  Future<List<PatientModel>> getAllPatients() async {
    try {
      final response = await _apiService.get('/patients');
      final List<dynamic> data = response.data['patients'] ?? [];
      return data.map((json) => PatientModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des patients: ${e.toString()}');
    }
  }

  /// Get patient by ID
  Future<PatientModel> getPatientById(String id) async {
    try {
      final response = await _apiService.get('/patients/$id');
      return PatientModel.fromJson(response.data['patient']);
    } catch (e) {
      throw Exception('Erreur lors du chargement du patient: ${e.toString()}');
    }
  }

  /// Search patients
  Future<List<PatientModel>> searchPatients(String query) async {
    try {
      final response = await _apiService.get(
        '/patients/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data['patients'] ?? [];
      return data.map((json) => PatientModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: ${e.toString()}');
    }
  }

  /// Update patient
  Future<PatientModel> updatePatient({
    required String id,
    String? nomComplet,
    String? telephone,
    String? email,
  }) async {
    try {
      final response = await _apiService.put(
        '/patients/$id',
        data: {
          if (nomComplet != null) 'nom_complet': nomComplet,
          if (telephone != null) 'telephone': telephone,
          if (email != null) 'email': email,
        },
      );
      return PatientModel.fromJson(response.data['patient']);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: ${e.toString()}');
    }
  }

  /// Delete patient
  Future<bool> deletePatient(String id) async {
    try {
      await _apiService.delete('/patients/$id');
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: ${e.toString()}');
    }
  }
}