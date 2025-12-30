// lib/repositories/dashboard_repository.dart

import 'package:pharma/data/models/dashboard_admin_model.dart';

import '../core/services/api_service.dart';
import '../data/models/dashboard_model.dart';

class DashboardRepository {
  final ApiService _apiService;

  DashboardRepository({required ApiService apiService})
      : _apiService = apiService;

  /// Récupérer les données du dashboard
  Future<DashboardModel> getDashboard({Map<String, dynamic>? filters}) async {
    try {
      final response = await _apiService.getDashboard(filters);
      return response;
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard: ${e.toString()}');
    }
  }


  /// Récupérer les données du dashboard
  Future<DashboardAdminModel> getDashboardAdmin({Map<String, dynamic>? filters}) async {
    try {
      final response = await _apiService.getDashboardAdmin(filters);
      return response;
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard: ${e.toString()}');
    }
  }

  /// Récupérer le dashboard par période
  Future<DashboardModel> getDashboardByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final filters = {
        'date_debut': startDate.toIso8601String().split('T')[0],
        'date_fin': endDate.toIso8601String().split('T')[0],
      };

      return await getDashboard(filters: filters);
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard par période: ${e.toString()}');
    }
  }

  /// Récupérer le dashboard par mois
  Future<DashboardModel> getDashboardByMonth(int year, int month) async {
    try {
      // Calculer premier et dernier jour du mois
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);

      return await getDashboardByPeriod(
        startDate: firstDay,
        endDate: lastDay,
      );
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard par mois: ${e.toString()}');
    }
  }

  /// Récupérer le dashboard par semaine
  Future<DashboardModel> getDashboardByWeek(DateTime date) async {
    try {
      // Calculer le début et la fin de la semaine
      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      return await getDashboardByPeriod(
        startDate: startOfWeek,
        endDate: endOfWeek,
      );
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard par semaine: ${e.toString()}');
    }
  }

  /// Récupérer le dashboard d'aujourd'hui
  Future<DashboardModel> getDashboardToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      return await getDashboardByPeriod(
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard d\'aujourd\'hui: ${e.toString()}');
    }
  }
}