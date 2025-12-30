class MedicamentModel {
  final String id;
  final String nom;
  final String dosage;
  final String forme;
  final String? laboratoire;
  final String? dci;
  final String? codeBarre;
  final String? description;
  final bool disponible;
  final int stock;
  final double? prix;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicamentModel({
    required this.id,
    required this.nom,
    required this.dosage,
    required this.forme,
    this.laboratoire,
    this.dci,
    this.codeBarre,
    this.description,
    this.disponible = false,
    this.stock = 0,
    this.prix,
    required this.createdAt,
    this.updatedAt,
  });

  // From JSON
  factory MedicamentModel.fromJson(Map<String, dynamic> json) {
    return MedicamentModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      dosage: json['dosage'] ?? '',
      forme: json['forme'] ?? '',
      laboratoire: json['laboratoire'],
      dci: json['dci'],
      codeBarre: json['code_barre'],
      description: json['description'],
      disponible: json['disponible'] ?? false,
      stock: json['stock'] ?? 0,
      prix: json['prix']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'dosage': dosage,
      'forme': forme,
      'laboratoire': laboratoire,
      'dci': dci,
      'code_barre': codeBarre,
      'description': description,
      'disponible': disponible,
      'stock': stock,
      'prix': prix,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Copy with
  MedicamentModel copyWith({
    String? id,
    String? nom,
    String? dosage,
    String? forme,
    String? laboratoire,
    String? dci,
    String? codeBarre,
    String? description,
    bool? disponible,
    int? stock,
    double? prix,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicamentModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      dosage: dosage ?? this.dosage,
      forme: forme ?? this.forme,
      laboratoire: laboratoire ?? this.laboratoire,
      dci: dci ?? this.dci,
      codeBarre: codeBarre ?? this.codeBarre,
      description: description ?? this.description,
      disponible: disponible ?? this.disponible,
      stock: stock ?? this.stock,
      prix: prix ?? this.prix,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get full name with dosage
  String get fullName => '$nom $dosage';

  // Get complete description
  String get completeDescription {
    final parts = [nom, dosage, forme];
    if (laboratoire != null) parts.add('- $laboratoire');
    return parts.join(' ');
  }

  // Check if in stock
  bool get inStock => disponible && stock > 0;

  // Check if low stock
  bool get isLowStock => stock > 0 && stock <= 5;

  // Check if out of stock
  bool get isOutOfStock => stock <= 0;

  // Get stock status
  String get stockStatus {
    if (isOutOfStock) return 'Rupture de stock';
    if (isLowStock) return 'Stock faible';
    return 'En stock';
  }

  // Format price
  String get formattedPrice {
    if (prix == null) return 'Prix non disponible';
    return '${prix!.toStringAsFixed(2)} DH';
  }

  @override
  String toString() {
    return 'MedicamentModel(id: $id, nom: $nom, dosage: $dosage, forme: $forme)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicamentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}