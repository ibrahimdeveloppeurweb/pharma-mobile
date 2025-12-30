// lib/data/models/dashboard_admin_model.dart

class DashboardAdminModel {
  final GraphDataAdmin graph;
  final WidgetsDataAdmin widgets;
  final List<TopPharmacieData> topPharmacies;
  final Map<String, int> repartitionVilles;

  DashboardAdminModel({
    required this.graph,
    required this.widgets,
    required this.topPharmacies,
    required this.repartitionVilles,
  });

  factory DashboardAdminModel.fromJson(Map<String, dynamic> json) {
    return DashboardAdminModel(
      graph: GraphDataAdmin.fromJson(json['graph'] ?? {}),
      widgets: WidgetsDataAdmin.fromJson(json['widgets'] ?? {}),
      topPharmacies: _parseTopPharmacies(json['top_pharmacies']),
      repartitionVilles: _parseRepartitionVilles(json['repartition_villes']),
    );
  }

  // ✅ MÉTHODE POUR PARSER TOP_PHARMACIES
  static List<TopPharmacieData> _parseTopPharmacies(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) => TopPharmacieData.fromJson(item)).toList();
    }
    return [];
  }

  // ✅ MÉTHODE POUR PARSER REPARTITION_VILLES
  static Map<String, int> _parseRepartitionVilles(dynamic data) {
    if (data == null) {
      return {};
    }

    // Si c'est déjà un Map
    if (data is Map) {
      final Map<String, int> result = {};
      data.forEach((key, value) {
        result[key.toString()] = _parseInt(value);
      });
      return result;
    }

    // Si c'est une List d'objets
    if (data is List) {
      final Map<String, int> result = {};
      for (var item in data) {
        if (item is Map) {
          // Format 1: {"ville": "Abidjan", "count": 50}
          if (item.containsKey('ville') && item.containsKey('count')) {
            result[item['ville'].toString()] = _parseInt(item['count']);
          }
          // Format 2: {"ville": "Abidjan", "nombre": 50}
          else if (item.containsKey('ville') && item.containsKey('nombre')) {
            result[item['ville'].toString()] = _parseInt(item['nombre']);
          }
          // Format 3: {"ville": "Abidjan", "total": 50}
          else if (item.containsKey('ville') && item.containsKey('total')) {
            result[item['ville'].toString()] = _parseInt(item['total']);
          }
          // Format 4: {"nom": "Abidjan", "count": 50}
          else if (item.containsKey('nom') && item.containsKey('count')) {
            result[item['nom'].toString()] = _parseInt(item['count']);
          }
        }
      }
      return result;
    }

    // Par défaut, retourner un Map vide
    return {};
  }

  // Helper pour convertir en int de façon sécurisée
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'graph': graph.toJson(),
      'widgets': widgets.toJson(),
      'top_pharmacies': topPharmacies.map((item) => item.toJson()).toList(),
      'repartition_villes': repartitionVilles,
    };
  }
}

// 📊 DONNÉES DU GRAPHIQUE ADMIN
class GraphDataAdmin {
  final List<int> nbInscriptions;
  final List<String> time;

  GraphDataAdmin({
    required this.nbInscriptions,
    required this.time,
  });

  factory GraphDataAdmin.fromJson(Map<String, dynamic> json) {
    return GraphDataAdmin(
      nbInscriptions: _parseIntList(json['nb_inscriptions']),
      time: _parseStringList(json['time']),
    );
  }

  // Méthode helper pour convertir une liste en List<int>
  static List<int> _parseIntList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) {
        if (e is int) return e;
        if (e is double) return e.toInt();
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
    }
    return [];
  }

  // Méthode helper pour convertir une liste en List<String>
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'nb_inscriptions': nbInscriptions,
      'time': time,
    };
  }

  // Helper pour obtenir les données du graphique formatées
  List<ChartDataAdmin> get chartDataList {
    List<ChartDataAdmin> data = [];
    for (int i = 0; i < time.length; i++) {
      data.add(ChartDataAdmin(
        month: time[i],
        value: nbInscriptions[i],
      ));
    }
    return data;
  }
}

// Helper class pour les données du graphique admin
class ChartDataAdmin {
  final String month;
  final int value;

  ChartDataAdmin({
    required this.month,
    required this.value,
  });
}

// 📈 DONNÉES DES WIDGETS/STATISTIQUES ADMIN
class WidgetsDataAdmin {
  final int totalPharmacies;
  final int pharmaciesActives;
  final int nouvellesInscriptions;
  final int tauxActivite;
  final int totalDemandes;
  final int demandesTraitees;

  WidgetsDataAdmin({
    required this.totalPharmacies,
    required this.pharmaciesActives,
    required this.nouvellesInscriptions,
    required this.tauxActivite,
    required this.totalDemandes,
    required this.demandesTraitees,
  });

  factory WidgetsDataAdmin.fromJson(Map<String, dynamic> json) {
    return WidgetsDataAdmin(
      totalPharmacies: _parseInt(json['total_pharmacies']),
      pharmaciesActives: _parseInt(json['pharmacies_actives']),
      nouvellesInscriptions: _parseInt(json['nouvelles_inscriptions']),
      tauxActivite: _parseInt(json['taux_activite']),
      totalDemandes: _parseInt(json['total_demandes']),
      demandesTraitees: _parseInt(json['demandes_traitees']),
    );
  }

  // Méthode helper pour convertir en int de façon sécurisée
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_pharmacies': totalPharmacies,
      'pharmacies_actives': pharmaciesActives,
      'nouvelles_inscriptions': nouvellesInscriptions,
      'taux_activite': tauxActivite,
      'total_demandes': totalDemandes,
      'demandes_traitees': demandesTraitees,
    };
  }

  // Helpers calculés
  int get pharmaciesInactives => totalPharmacies - pharmaciesActives;

  int get demandesEnCours => totalDemandes - demandesTraitees;

  double get tauxTraitement {
    if (totalDemandes == 0) return 0;
    return (demandesTraitees / totalDemandes) * 100;
  }
}

// 🏆 TOP PHARMACIES
class TopPharmacieData {
  final String nom;
  final int demandes;
  final String ville;

  TopPharmacieData({
    required this.nom,
    required this.demandes,
    required this.ville,
  });

  factory TopPharmacieData.fromJson(Map<String, dynamic> json) {
    return TopPharmacieData(
      nom: json['nom']?.toString() ?? '',
      demandes: _parseInt(json['demandes']),
      ville: json['ville']?.toString() ?? '',
    );
  }

  // Méthode helper pour convertir en int de façon sécurisée
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'demandes': demandes,
      'ville': ville,
    };
  }
}