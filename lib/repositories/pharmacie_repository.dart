// lib/repositories/pharmacie_repository.dart
import 'package:pharma/config/constants.dart';
import 'package:pharma/data/models/pharmacie_model.dart';

import '../../core/services/api_service.dart';


class PharmacieRepository {
  final ApiService _apiService = ApiService();

  // Get pharmacies statistics (pour dashboard admin)
  Future<Map<String, dynamic>> getPharmaciesStats(Map<String, dynamic>? filters) async {
    try {
      final response = await _apiService.get(
        "/${ApiEndPoints.pharmaciesStatsEndpoint}",
        queryParameters: filters,
      );

      print("Dashboard Status code: ${response.statusCode}");
      print("Dashboard Response: ${response.data}");
      print("response.data['data'] ${response.data['data']}");
      // Si votre API retourne les données dans un objet 'data'
      final data = response.data['data'] ?? response.data;

      return data;
    } catch (e) {
      throw Exception('Erreur de chargement des statistiques: ${e.toString()}');
    }
  }

  // Get liste complète des pharmacies
  Future<List<PharmacieModel>> getPharmacies(Map<String, dynamic>? filters) async {
    try {
      final response = await _apiService.get(
        "/${ApiEndPoints.pharmaciesEndpoint}",
        queryParameters: filters,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['data'] ?? [];

        print("response ${response}");
        return data.map((item) => PharmacieModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Erreur de chargement des pharmacies: ${e.toString()}');
    }
  }

  // Get une pharmacie par ID
  Future<PharmacieModel?> getPharmacieById(int id) async {
    try {
      final response = await _apiService.get('/pharmacies/$id');

      if (response.statusCode == 200) {
        return PharmacieModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur de chargement: ${e.toString()}');
    }
  }

  // Créer une pharmacie
  Future<PharmacieModel?> createPharmacie(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post("/${ApiEndPoints.pharmaciesEndpoint}/new", data: data);

      print("Pharmacie Response: ${response.data['data']}");
      print("response.data['data'] ${response.data['data']}");
      // Si votre API retourne les données dans un objet 'data'

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return PharmacieModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur de création: ${e.toString()}');
    }
  }

  // Mettre à jour une pharmacie
  Future<PharmacieModel?> updatePharmacie(
      String uuid,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await _apiService.post('/${ApiEndPoints.pharmaciesEndpoint}/$uuid/edit', data: data);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return PharmacieModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur de mise à jour: ${e.toString()}');
    }
  }

  // Supprimer une pharmacie
Future<bool> deletePharmacie(String? uuid) async {
    try {
      final response = await _apiService.delete('/${ApiEndPoints.pharmaciesEndpoint}/$uuid/delete');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Erreur de suppression: ${e.toString()}');
    }
  }

  // Activer/Désactiver une pharmacie
  Future<bool> togglePharmacieStatus(int id, bool actif) async {
    try {
      final response = await _apiService.patch(
        '/pharmacies/$id/status',
        data: {'actif': actif},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur de changement de statut: ${e.toString()}');
    }
  }

  // Get pharmacies par ville
  Future<List<String>> getVilles() async {
    try {
      final response = await _apiService.get('/pharmacies/villes');

      if (response.statusCode == 200) {
        return List<String>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}