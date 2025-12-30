import 'package:pharma/shared/enums/statut_demande.dart';

class DemandeModel {
  final String uuid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime dateCreation;
  final double? prixTotal;
  final DemandeInfo info;
  final String create;
  final String? update;
  final String? remove;

  DemandeModel({
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    required this.dateCreation,
    this.prixTotal,
    required this.info,
    required this.create,
    this.update,
    this.remove,
  });

  // Getters pour compatibilité avec le code existant
  String get id => uuid;
  PatientInfo get patient => PatientInfo(nomComplet: info.patient, telephone: info.telephone);
  MedicamentInfo get medicament => info.demandeMedicaments.isNotEmpty
      ? MedicamentInfo(
    nom: info.demandeMedicaments.map((m) => m.medicament).join(', '),
    id: info.demandeMedicaments.first.id.toString(),
  )
      : MedicamentInfo(nom: 'Aucun médicament', id: '0');
  StatutDemande get statut => StatutDemandeExtension.fromString(info.statut);

  factory DemandeModel.fromJson(Map<String, dynamic> json) {
    return DemandeModel(
      uuid: json['uuid'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      dateCreation: DateTime.parse(json['dateCreation']),
      prixTotal: json['prixTotal']?.toDouble(),
      info: DemandeInfo.fromJson(json['info']),
      create: json['create'] ?? '',
      update: json['update'],
      remove: json['remove'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dateCreation': dateCreation.toIso8601String(),
      'prixTotal': prixTotal,
      'info': info.toJson(),
      'create': create,
      'update': update,
      'remove': remove,
    };
  }
}

// Classe pour les informations de la demande
class DemandeInfo {
  final String patient;
  final String telephone;
  final String statut;
  final String mode_paiement;
  final List<HistoriqueItem> historique;
  final List<DemandeMedicament> demandeMedicaments;

  DemandeInfo({
    required this.patient,
    required this.telephone,
    required this.statut,
    required this.mode_paiement,
    required this.historique,
    required this.demandeMedicaments,
  });

  factory DemandeInfo.fromJson(Map<String, dynamic> json) {
    return DemandeInfo(
      patient: json['patient'] ?? '',
      telephone: json['telephone'] ?? '',
      statut: json['statut'] ?? 'en_attente',
      mode_paiement: json['mode_paiement'] ?? '',
      historique: (json['historique'] as List<dynamic>?)
          ?.map((h) => HistoriqueItem.fromJson(h))
          .toList() ??
          [],
      demandeMedicaments: (json['demandeMedicaments'] as List<dynamic>?)
          ?.map((m) => DemandeMedicament.fromJson(m))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient': patient,
      'telephone': telephone,
      'statut': statut,
      'mode_paiement': mode_paiement,
      'historique': historique.map((h) => h.toJson()).toList(),
      'demandeMedicaments': demandeMedicaments.map((m) => m.toJson()).toList(),
    };
  }
}

// Classe pour l'historique
class HistoriqueItem {
  final String date;
  final String message;

  HistoriqueItem({
    required this.date,
    required this.message,
  });

  factory HistoriqueItem.fromJson(Map<String, dynamic> json) {
    return HistoriqueItem(
      date: json['date'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'message': message,
    };
  }
}

// Classe pour les médicaments demandés
class DemandeMedicament {
  final int id;
  final int quantite;
  final double prix;
  final String medicament;

  DemandeMedicament({
    required this.id,
    required this.quantite,
    required this.prix,
    required this.medicament,
  });

  factory DemandeMedicament.fromJson(Map<String, dynamic> json) {
    return DemandeMedicament(
      id: json['id'],
      quantite: json['quantite'],
      prix: (json['prix'] as num).toDouble(),
      medicament: json['medicament'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantite': quantite,
      'prix': prix,
      'medicament': medicament,
    };
  }
}

// Classes simplifiées pour compatibilité
class PatientInfo {
  final String nomComplet;
  final String telephone;

  PatientInfo({
    required this.nomComplet,
    required this.telephone,
  });
}

class MedicamentInfo {
  final String nom;
  final String id;

  MedicamentInfo({
    required this.nom,
    required this.id,
  });
}