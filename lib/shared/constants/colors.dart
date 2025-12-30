import 'package:flutter/material.dart';

class AppColors {
  // Couleur principale (vert pharmacie)
  static const Color primary = Color(0xFF2E6A5B);
  static const Color primaryLight = Color(0xFFE8F5E8);
  static const Color primaryDark = Color(0xFF0D6B0D);

  // Couleurs de statut
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Couleurs de fond
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Couleurs de bordure
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Couleurs d'ombre
  static Color shadow = Colors.black.withOpacity(0.1);
  static Color shadowLight = Colors.black.withOpacity(0.05);

  // Couleurs de gradient
  static const List<Color> primaryGradient = [
    Color(0xFF129512),
    Color(0xFF0D6B0D),
  ];

  // Couleurs désactivées
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color disabledText = Color(0xFF9CA3AF);
}