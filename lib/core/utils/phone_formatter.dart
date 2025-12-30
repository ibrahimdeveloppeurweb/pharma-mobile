import 'package:flutter/services.dart';

class PhoneFormatter {
  // Format phone number with spaces (ex: 0612345678 -> 06 12 34 56 78)
  static String formatPhone(String phone) {
    // Remove all non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.isEmpty) return '';

    // Format according to length
    if (cleaned.length <= 2) {
      return cleaned;
    } else if (cleaned.length <= 4) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2)}';
    } else if (cleaned.length <= 6) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4)}';
    } else if (cleaned.length <= 8) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6)}';
    } else if (cleaned.length <= 10) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8)}';
    } else {
      // For numbers longer than 10 digits
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8, 10)}';
    }
  }

  // Clean phone number (remove spaces, dashes, parentheses)
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  // Add international prefix (ex: 0612345678 -> +212612345678)
  static String addInternationalPrefix(String phone, {String countryCode = '+212'}) {
    final cleaned = cleanPhone(phone);

    // If already has +, return as is
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // If starts with 0, remove it
    if (cleaned.startsWith('0')) {
      return '$countryCode${cleaned.substring(1)}';
    }

    return '$countryCode$cleaned';
  }

  // Remove international prefix (ex: +212612345678 -> 0612345678)
  static String removeInternationalPrefix(String phone, {String countryCode = '+212'}) {
    final cleaned = cleanPhone(phone);

    if (cleaned.startsWith(countryCode)) {
      return '0${cleaned.substring(countryCode.length)}';
    }

    return cleaned;
  }

  // Validate phone format
  static bool isValidPhone(String phone) {
    final cleaned = cleanPhone(phone);

    // Check if contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return false;
    }

    // Check length
    if (cleaned.length < 10 || cleaned.length > 15) {
      return false;
    }

    // Check if starts with valid prefix (Morocco)
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return RegExp(r'^0[5-7]').hasMatch(cleaned);
    }

    return true;
  }

  // Format for display
  static String formatForDisplay(String phone) {
    final cleaned = cleanPhone(phone);

    if (cleaned.isEmpty) return '';

    // If international format
    if (cleaned.startsWith('+')) {
      return formatInternational(cleaned);
    }

    // Local format
    return formatPhone(cleaned);
  }

  // Format international number
  static String formatInternational(String phone) {
    final cleaned = cleanPhone(phone);

    if (!cleaned.startsWith('+')) {
      return formatPhone(cleaned);
    }

    // Extract country code and number
    final match = RegExp(r'^\+(\d{1,3})(.*)$').firstMatch(cleaned);
    if (match == null) return phone;

    final countryCode = match.group(1)!;
    final number = match.group(2)!;

    return '+$countryCode ${formatPhone(number)}';
  }

  // Get country code from phone number
  static String? getCountryCode(String phone) {
    final cleaned = cleanPhone(phone);

    if (!cleaned.startsWith('+')) return null;

    final match = RegExp(r'^\+(\d{1,3})').firstMatch(cleaned);
    return match?.group(1);
  }

  // Check if phone is mobile (Morocco)
  static bool isMobilePhone(String phone) {
    final cleaned = cleanPhone(phone);

    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return RegExp(r'^0[67]').hasMatch(cleaned);
    }

    if (cleaned.startsWith('+212')) {
      final number = cleaned.substring(4);
      return RegExp(r'^[67]').hasMatch(number);
    }

    return false;
  }

  // Check if phone is landline (Morocco)
  static bool isLandline(String phone) {
    final cleaned = cleanPhone(phone);

    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return RegExp(r'^05').hasMatch(cleaned);
    }

    if (cleaned.startsWith('+212')) {
      final number = cleaned.substring(4);
      return RegExp(r'^5').hasMatch(number);
    }

    return false;
  }

  // Mask phone number (ex: 0612345678 -> 06 ** ** ** 78)
  static String maskPhone(String phone) {
    final formatted = formatPhone(phone);

    if (formatted.length < 14) return formatted;

    return '${formatted.substring(0, 5)}** ** **${formatted.substring(formatted.length - 3)}';
  }
}

// TextInputFormatter for phone fields
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    // Remove all non-digit characters
    final cleaned = text.replaceAll(RegExp(r'\D'), '');

    // Limit to 10 digits
    if (cleaned.length > 10) {
      return oldValue;
    }

    // Format the phone number
    final formatted = PhoneFormatter.formatPhone(cleaned);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}