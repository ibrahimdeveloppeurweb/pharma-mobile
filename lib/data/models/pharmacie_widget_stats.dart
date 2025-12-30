// lib/core/models/pharmacie_widget_stats.dart
class PharmacieWidgetStats {
  final int totalPharmacies;
  final int pharmaciesActives;
  final int totalDemandes;
  final int notificationsTotal;

  PharmacieWidgetStats({
    required this.totalPharmacies,
    required this.pharmaciesActives,
    required this.totalDemandes,
    required this.notificationsTotal,
  });

  factory PharmacieWidgetStats.fromJson(Map<String, dynamic> json) {
    return PharmacieWidgetStats(
      totalPharmacies: json['total_pharmacies'] ?? 0,
      pharmaciesActives: json['pharmacies_actives'] ?? 0,
      totalDemandes: json['total_demandes'] ?? 0,
      notificationsTotal: json['notifications_total'] ?? 0,
    );
  }

  // Helper pour le taux d'activité
  double get tauxActivite {
    if (totalPharmacies == 0) return 0.0;
    return (pharmaciesActives / totalPharmacies) * 100;
  }
}