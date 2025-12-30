import '../core/services/api_service.dart';
import '../data/models/medicament_model.dart';

class MedicamentRepository {
  final ApiService _apiService;

  MedicamentRepository({required ApiService apiService})
      : _apiService = apiService;

  /// Get or create medicament
  Future<MedicamentModel> getOrCreateMedicament({
    required String nom,
    required String dosage,
    required String forme,
    String? laboratoire,
  }) async {
    try {
      // First try to find existing medicament
      final searchResponse = await _apiService.get(
        '/medicaments/search',
        queryParameters: {
          'nom': nom,
          'dosage': dosage,
          'forme': forme,
        },
      );

      if (searchResponse.data['medicaments'] != null &&
          (searchResponse.data['medicaments'] as List).isNotEmpty) {
        return MedicamentModel.fromJson(searchResponse.data['medicaments'][0]);
      }

      // If not found, create new medicament
      final response = await _apiService.post(
        '/medicaments',
        data: {
          'nom': nom,
          'dosage': dosage,
          'forme': forme,
          if (laboratoire != null) 'laboratoire': laboratoire,
        },
      );
      return MedicamentModel.fromJson(response.data['medicament']);
    } catch (e) {
      throw Exception('Erreur médicament: ${e.toString()}');
    }
  }

  /// Get all medicaments
  Future<List<MedicamentModel>> getAllMedicaments() async {
    try {
      final response = await _apiService.get('/medicaments');
      final List<dynamic> data = response.data['medicaments'] ?? [];
      return data.map((json) => MedicamentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des médicaments: ${e.toString()}');
    }
  }

  /// Get medicament by ID
  Future<MedicamentModel> getMedicamentById(String id) async {
    try {
      final response = await _apiService.get('/medicaments/$id');
      return MedicamentModel.fromJson(response.data['medicament']);
    } catch (e) {
      throw Exception('Erreur lors du chargement du médicament: ${e.toString()}');
    }
  }

  /// Search medicaments
  Future<List<MedicamentModel>> searchMedicaments(String query) async {
    try {
      final response = await _apiService.get(
        '/medicaments/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data['medicaments'] ?? [];
      return data.map((json) => MedicamentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: ${e.toString()}');
    }
  }

  /// Update medicament
  Future<MedicamentModel> updateMedicament({
    required String id,
    String? nom,
    String? dosage,
    String? forme,
    String? laboratoire,
  }) async {
    try {
      final response = await _apiService.put(
        '/medicaments/$id',
        data: {
          if (nom != null) 'nom': nom,
          if (dosage != null) 'dosage': dosage,
          if (forme != null) 'forme': forme,
          if (laboratoire != null) 'laboratoire': laboratoire,
        },
      );
      return MedicamentModel.fromJson(response.data['medicament']);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: ${e.toString()}');
    }
  }

  /// Delete medicament
  Future<bool> deleteMedicament(String id) async {
    try {
      await _apiService.delete('/medicaments/$id');
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: ${e.toString()}');
    }
  }

  /// Get top medicaments (most requested)
  Future<List<Map<String, dynamic>>> getTopMedicaments({int limit = 5}) async {
    try {
      final response = await _apiService.get(
        '/medicaments/top',
        queryParameters: {'limit': limit},
      );
      final List<dynamic> data = response.data['medicaments'] ?? [];
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des top médicaments: ${e.toString()}');
    }
  }
}