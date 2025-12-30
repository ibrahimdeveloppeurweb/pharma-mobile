class UserModel {
  final int id;
  final String uuid;
  final String email;
  final String nom;
  final String contact;
  final String adresse;
  final String pharmacie;
  final String refreshToken;
  final String role;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.uuid,
    required this.email,
    required this.nom,
    required this.contact,
    required this.adresse,
    required this.pharmacie,
    required this.refreshToken,
    this.role = 'pharmacien',
    this.emailVerified = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      contact: json['contact'] ?? '',
      adresse: json['adresse'] ?? '',
      pharmacie: json['pharmacie'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      role: json['role'] ?? 'pharmacien',
      emailVerified: json['email_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'email': email,
      'nom': nom,
      'contact': contact,
      'adresse': adresse,
      'pharmacie': pharmacie,
      'refreshToken': refreshToken,
      'role': role,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Copy with
  UserModel copyWith({
    int? id,
    String? uuid,
    String? email,
    String? nom,
    String? contact,
    String? adresse,
    String? pharmacie,
    String? refreshToken,
    String? role,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      contact: contact ?? this.contact,
      adresse: adresse ?? this.adresse,
      pharmacie: pharmacie ?? this.pharmacie,
      refreshToken: refreshToken ?? this.refreshToken,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get user initials
  String get initials {
    final names = nom.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return nom.isNotEmpty ? nom[0].toUpperCase() : '?';
  }

  // Get first name
  String get firstName {
    return nom.split(' ').first;
  }

  // Get last name
  String get lastName {
    final names = nom.split(' ');
    return names.length > 1 ? names.sublist(1).join(' ') : '';
  }

  // Check if admin
  bool get isAdmin => role == 'admin';

  // Check if pharmacien
  bool get isPharmacien => role == 'pharmacien';

  @override
  String toString() {
    return 'UserModel(id: $id, uuid: $uuid, nom: $nom, email: $email, pharmacie: $pharmacie)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}