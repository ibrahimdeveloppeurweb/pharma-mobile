import 'dart:io';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class TextractService {
  final ApiService _apiService = ApiService();

  // Extract text from image using AWS Textract
  Future<Map<String, dynamic>> extractTextFromImage(File imageFile) async {
    try {
      // Upload image to backend which will use AWS Textract
      final response = await _apiService.uploadFile(
        '/textract/extract',
        imageFile.path,
        fieldName: 'image',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erreur lors de l\'extraction du texte');
      }
    } catch (e) {
      throw Exception('Échec de l\'extraction: ${e.toString()}');
    }
  }

  // Parse medication info from extracted text
  Future<MedicamentInfo> parseMedicamentInfo(File imageFile) async {
    try {
      final extractedData = await extractTextFromImage(imageFile);

      return MedicamentInfo(
        nom: extractedData['nom'] ?? '',
        dosage: extractedData['dosage'] ?? '',
        forme: extractedData['forme'] ?? '',
        quantite: extractedData['quantite'] ?? '',
        laboratoire: extractedData['laboratoire'],
        codeBarre: extractedData['code_barre'],
        dateExpiration: extractedData['date_expiration'],
        rawText: extractedData['raw_text'] ?? '',
        confidence: (extractedData['confidence'] ?? 0.0).toDouble(),
      );
    } catch (e) {
      throw Exception('Erreur d\'analyse: ${e.toString()}');
    }
  }

  // Extract specific field from image
  Future<String?> extractField(File imageFile, String fieldName) async {
    try {
      final response = await _apiService.uploadFile(
        '/textract/extract-field',
        imageFile.path,
        fieldName: 'image',
        additionalData: {'field': fieldName},
      );

      if (response.statusCode == 200) {
        return response.data['value'];
      }
      return null;
    } catch (e) {
      throw Exception('Erreur d\'extraction du champ: ${e.toString()}');
    }
  }

  // Validate image before processing
  bool validateImage(File imageFile) {
    // Check file size
    final fileSize = imageFile.lengthSync();
    if (fileSize > 5 * 1024 * 1024) { // 5 MB
      throw Exception('L\'image ne doit pas dépasser 5 MB');
    }

    // Check file extension
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      throw Exception('Format d\'image non supporté. Utilisez JPG, JPEG ou PNG');
    }

    return true;
  }

  // Process multiple images
  Future<List<MedicamentInfo>> processMultipleImages(List<File> imageFiles) async {
    final results = <MedicamentInfo>[];

    for (final imageFile in imageFiles) {
      try {
        final info = await parseMedicamentInfo(imageFile);
        results.add(info);
      } catch (e) {
        // Continue with other images even if one fails
        continue;
      }
    }

    return results;
  }
}

// Model for medication information
class MedicamentInfo {
  final String nom;
  final String dosage;
  final String forme;
  final String quantite;
  final String? laboratoire;
  final String? codeBarre;
  final String? dateExpiration;
  final String rawText;
  final double confidence;

  MedicamentInfo({
    required this.nom,
    required this.dosage,
    required this.forme,
    required this.quantite,
    this.laboratoire,
    this.codeBarre,
    this.dateExpiration,
    required this.rawText,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'dosage': dosage,
      'forme': forme,
      'quantite': quantite,
      'laboratoire': laboratoire,
      'code_barre': codeBarre,
      'date_expiration': dateExpiration,
      'raw_text': rawText,
      'confidence': confidence,
    };
  }

  factory MedicamentInfo.fromJson(Map<String, dynamic> json) {
    return MedicamentInfo(
      nom: json['nom'] ?? '',
      dosage: json['dosage'] ?? '',
      forme: json['forme'] ?? '',
      quantite: json['quantite'] ?? '',
      laboratoire: json['laboratoire'],
      codeBarre: json['code_barre'],
      dateExpiration: json['date_expiration'],
      rawText: json['raw_text'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return '$nom $dosage - $forme ($quantite)';
  }

  bool get isValid {
    return nom.isNotEmpty && dosage.isNotEmpty && forme.isNotEmpty;
  }

  bool get hasHighConfidence {
    return confidence >= 0.8;
  }
}