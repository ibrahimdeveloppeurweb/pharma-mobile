// lib/data/models/medicine.dart
class MedicineModel {
  final String uuid;
  final String nom;
  final String prix;

  MedicineModel({
    required this.uuid,
    required this.nom,
    required this.prix,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      uuid: json['uuid'] as String,
      nom: json['nom'] as String,
      prix: json['prix'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'nom': nom,
      'prix': prix,
    };
  }
}