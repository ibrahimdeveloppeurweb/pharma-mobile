class PatientModel {
  final String id;
  final String nomComplet;
  final String telephone;
  final String? email;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int totalDemandes;
  final int demandesEnAttente;

  PatientModel({
    required this.id,
    required this.nomComplet,
    required this.telephone,
    this.email,
    required this.createdAt,
    this.updatedAt,
    this.totalDemandes = 0,
    this.demandesEnAttente = 0,
  });

  // From JSON
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      nomComplet: json['nom_complet'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      totalDemandes: json['total_demandes'] ?? 0,
      demandesEnAttente: json['demandes_en_attente'] ?? 0,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_complet': nomComplet,
      'telephone': telephone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total_demandes': totalDemandes,
      'demandes_en_attente': demandesEnAttente,
    };
  }

  // Copy with
  PatientModel copyWith({
    String? id,
    String? nomComplet,
    String? telephone,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalDemandes,
    int? demandesEnAttente,
  }) {
    return PatientModel(
      id: id ?? this.id,
      nomComplet: nomComplet ?? this.nomComplet,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalDemandes: totalDemandes ?? this.totalDemandes,
      demandesEnAttente: demandesEnAttente ?? this.demandesEnAttente,
    );
  }

  // Get patient initials
  String get initials {
    final names = nomComplet.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : '?';
  }

  // Get first name
  String get firstName {
    return nomComplet.split(' ').first;
  }

  // Format phone number
  String get formattedPhone {
    final cleaned = telephone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8)}';
    }
    return telephone;
  }

  // Check if has pending requests
  bool get hasPendingRequests => demandesEnAttente > 0;

  // Check if is frequent patient
  bool get isFrequentPatient => totalDemandes >= 5;

  @override
  String toString() {
    return 'PatientModel(id: $id, nomComplet: $nomComplet, telephone: $telephone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatientModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}