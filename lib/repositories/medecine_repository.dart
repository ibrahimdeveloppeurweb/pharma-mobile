// lib/repositories/medicine_repository.dart
import 'package:flutter/material.dart';
import 'package:pharma/config/constants.dart';
import 'package:pharma/data/models/medicine_model.dart';
import '../core/services/api_service.dart';

class MedicineRepository {
  final ApiService apiService;

  MedicineRepository({required this.apiService});

  /// Récupérer les médicaments avec pagination
  Future<Map<String, dynamic>> getMedicinesPaginated({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await apiService.get(
        "/${ApiEndPoints.medicamentPublicGetEndpoint}",
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      debugPrint('📥 Response page $page : ${response.data}');

      // Structure : response.data['data']['medecine']
      final dataWrapper = response.data['data'];

      // Les médicaments
      final List<dynamic> medicinesData = dataWrapper['medecine'] ?? [];
      final List<MedicineModel> medicines = medicinesData
          .map((json) => MedicineModel.fromJson(json))
          .toList();

      // La pagination
      final Map<String, dynamic> pagination = dataWrapper['pagination'] ?? {};

      debugPrint('✅ Page $page : ${medicines.length} médicaments chargés');

      return {
        'data': medicines,
        'pagination': pagination,
      };

    } catch (e) {
      debugPrint('❌ Erreur getMedicinesPaginated page $page : $e');
      throw Exception('Erreur lors du chargement des médicaments (page $page): $e');
    }
  }

  /// Récupérer tous les médicaments (sans pagination)
  Future<List<MedicineModel>> getMedicines() async {
    try {
      final response = await apiService.get("/${ApiEndPoints.medicamentPublicGetEndpoint}");

      final dataWrapper = response.data['data'];

      if (dataWrapper != null && dataWrapper['medecine'] != null) {
        final List<dynamic> data = dataWrapper['medecine'];
        return data.map((json) => MedicineModel.fromJson(json)).toList();
      } else if (response.data['data'] is List) {
        // Compatibilité ancienne structure
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MedicineModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Erreur getMedicines: $e');
      throw Exception('Erreur lors du chargement des médicaments: $e');
    }
  }

  /// Rechercher des médicaments
  Future<List<MedicineModel>> searchMedicines(String query) async {
    try {
      final response = await apiService.get(
        '/medicaments/search',
        queryParameters: {'q': query},
      );

      final dataWrapper = response.data['data'];

      if (dataWrapper != null && dataWrapper['medecine'] != null) {
        final List<dynamic> data = dataWrapper['medecine'];
        return data.map((json) => MedicineModel.fromJson(json)).toList();
      } else if (response.data['data'] is List) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MedicineModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Erreur searchMedicines: $e');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir un médicament par UUID
  Future<MedicineModel> getMedicineByUuid(String uuid) async {
    try {
      final response = await apiService.get('/medicaments/$uuid');

      final dataWrapper = response.data['data'];

      if (dataWrapper != null && dataWrapper is Map<String, dynamic>) {
        return MedicineModel.fromJson(dataWrapper);
      } else {
        throw Exception('Médicament introuvable');
      }
    } catch (e) {
      debugPrint('❌ Erreur getMedicineByUuid: $e');
      throw Exception('Erreur lors de la récupération du médicament: $e');
    }
  }
}