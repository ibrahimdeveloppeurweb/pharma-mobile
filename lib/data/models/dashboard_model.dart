class DashboardModel {
  final GraphData graph;
  final List<MedicamentStat> medicaments;
  final PrcData prc;
  final WidgetData widget;

  DashboardModel({
    required this.graph,
    required this.medicaments,
    required this.prc,
    required this.widget,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      graph: GraphData.fromJson(json['graph'] ?? {}),
      medicaments: (json['medicaments'] as List<dynamic>?)
          ?.map((item) => MedicamentStat.fromJson(item))
          .toList() ??
          [],
      prc: PrcData.fromJson(json['prc'] ?? {}),
      widget: WidgetData.fromJson(json['widget'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'graph': graph.toJson(),
      'medicaments': medicaments.map((item) => item.toJson()).toList(),
      'prc': prc.toJson(),
      'widget': widget.toJson(),
    };
  }
}

// Modèle pour les données du graphique
class GraphData {
  final List<int> nbD;
  final List<String> time;

  GraphData({
    required this.nbD,
    required this.time,
  });

  factory GraphData.fromJson(Map<String, dynamic> json) {
    return GraphData(
      // ✅ CORRECTION : Convertir les nombres en int
      nbD: (json['nb_d'] as List<dynamic>?)
          ?.map((item) => (item as num).toInt())
          .toList() ??
          [],
      time: (json['time'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nb_d': nbD,
      'time': time,
    };
  }
}

// Modèle pour les statistiques des médicaments
class MedicamentStat {
  final String medicament;
  final int nbDemandes;

  MedicamentStat({
    required this.medicament,
    required this.nbDemandes,
  });

  factory MedicamentStat.fromJson(Map<String, dynamic> json) {
    return MedicamentStat(
      medicament: json['medicament']?.toString() ?? '',
      // ✅ CORRECTION : Convertir en int
      nbDemandes: (json['nbDemandes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicament': medicament,
      'nbDemandes': nbDemandes,
    };
  }
}

// Modèle pour les pourcentages
class PrcData {
  final int prcN;
  final int prcR;

  PrcData({
    required this.prcN,
    required this.prcR,
  });

  factory PrcData.fromJson(Map<String, dynamic> json) {
    return PrcData(
      // ✅ CORRECTION : Convertir en int
      prcN: (json['prcN'] as num?)?.toInt() ?? 0,
      prcR: (json['prcR'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prcN': prcN,
      'prcR': prcR,
    };
  }
}

// Modèle pour les widgets de statistiques
class WidgetData {
  final int somR;
  final int enAttente;
  final int notifie;
  final int recupere;

  WidgetData({
    required this.somR,
    required this.enAttente,
    required this.notifie,
    required this.recupere,
  });

  factory WidgetData.fromJson(Map<String, dynamic> json) {
    return WidgetData(
      // ✅ CORRECTION : Convertir tous les nombres en int
      somR: (json['somR'] as num?)?.toInt() ?? 0,
      enAttente: (json['en_attente'] as num?)?.toInt() ?? 0,
      notifie: (json['notifie'] as num?)?.toInt() ?? 0,
      recupere: (json['recupere'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'somR': somR,
      'en_attente': enAttente,
      'notifie': notifie,
      'recupere': recupere,
    };
  }

  // Calculer le total des demandes
  int get totalDemandes => enAttente + notifie + recupere;
}