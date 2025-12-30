// lib/core/models/pharmacie_model.dart
class PharmacieModel {
  final int? id;
  final String nom;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? numeroAutorisation;
  final String ville;
  final String? codePostal;
  final String? uuid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int totalDemandes;
  final int demandesNotifiees;
  final int? demandesEnAttente;
  final int? demandesRecuperees;
  final int? tauxPerformance;
  final bool? actif;
  final bool? abonnementActif;
  final bool? faveurActive;
  final int? rang;

  PharmacieModel({
    this.id,
    required this.nom,
    this.adresse,
    this.telephone,
    this.email,
    this.numeroAutorisation,
    required this.ville,
    this.codePostal,
    this.uuid,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.totalDemandes,
    required this.demandesNotifiees,
    this.demandesEnAttente,
    this.demandesRecuperees,
    this.tauxPerformance,
    this.actif,
    this.abonnementActif,
    this.faveurActive,
    this.rang,
  });

  // Factory pour le retour API de statistiques
  factory PharmacieModel.fromStatsJson(Map<String, dynamic> json) {
    return PharmacieModel(
      nom: json['nom'] ?? '',
      ville: json['ville'] ?? '',
      totalDemandes: json['total_demandes'] ?? 0,
      demandesNotifiees: json['demandes_notifiees'] ?? 0,
      tauxPerformance: json['taux_performance'] ?? 0,
      actif: json['actif'] ?? false,
      abonnementActif: json['abonnementActif'] ?? false,
      rang: json['rang'] ?? 0,
    );
  }

  // Factory pour le retour API détaillé
  factory PharmacieModel.fromJson(Map<String, dynamic> json) {
    return PharmacieModel(
      id: json['id'],
      nom: json['nom'] ?? '',
      adresse: json['adresse'],
      telephone: json['telephone'],
      email: json['email'],
      numeroAutorisation: json['numeroAutorisation'],
      ville: json['ville'] ?? '',
      codePostal: json['codePostal'],
      uuid: json['uuid'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
      totalDemandes: json['total_demandes'] ?? 0,
      demandesNotifiees: json['demandes_notifiees'] ?? 0,
      demandesEnAttente: json['demandes_en_attente'],
      demandesRecuperees: json['demandes_recuperees'],
      actif: json['actif'],
      abonnementActif: json['abonnementActif'],
      faveurActive: json['faveurActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'numeroAutorisation': numeroAutorisation,
      'ville': ville,
      'codePostal': codePostal,
      'uuid': uuid,
      'total_demandes': totalDemandes,
      'demandes_notifiees': demandesNotifiees,
      'demandes_en_attente': demandesEnAttente,
      'demandes_recuperees': demandesRecuperees,
      'taux_performance': tauxPerformance,
      'actif': actif,
      'abonnementActif': abonnementActif,
      'faveurActive': faveurActive,

      'rang': rang,
    };
  }

  // Helpers
  String get statusLabel => actif == true ? 'Active' : 'Inactive';

  String get performanceLabel {
    if (tauxPerformance == null) return 'N/A';
    if (tauxPerformance! >= 80) return 'Excellent';
    if (tauxPerformance! >= 60) return 'Bon';
    if (tauxPerformance! >= 40) return 'Moyen';
    return 'Faible';
  }
}