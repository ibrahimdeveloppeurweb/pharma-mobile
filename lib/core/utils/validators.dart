class Validators {
  // Empêcher l'instanciation de la classe
  Validators._();

  // Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }

    return null;
  }

  // Password Validator
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }

    return null;
  }

  // Password Confirmation Validator
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'La confirmation du mot de passe est requise';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  // Phone Number Validator
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }

    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!RegExp(r'^[0-9]+$').hasMatch(cleanedPhone)) {
      return 'Le numéro de téléphone ne doit contenir que des chiffres';
    }

    if (cleanedPhone.length < 10 || cleanedPhone.length > 15) {
      return 'Le numéro de téléphone doit contenir entre 10 et 15 chiffres';
    }

    // if (cleanedPhone.startsWith('0') && cleanedPhone.length == 10) {
    //   if (!RegExp(r'^0[5-7]').hasMatch(cleanedPhone)) {
    //     return 'Le numéro doit commencer par 05, 06 ou 07';
    //   }
    // }

    return null;
  }

// Name Validator
// Name Validator
  static String? validateName(String? value, {String? fieldName}) {
    final field = fieldName ?? 'Le nom';

    if (value == null || value.isEmpty) {
      return '$field est requis';
    }

    if (value.length < 2) {
      return '$field doit contenir au moins 2 caractères';
    }

    if (value.length > 50) {
      return '$field ne doit pas dépasser 50 caractères';
    }

    // Accepte les lettres avec accents, espaces, tirets et apostrophes
    final nameRegex = RegExp(r"^[a-zA-ZàâäæçéèêëïîôùûüÿœÀÂÄÆÇÉÈÊËÏÎÔÙÛÜŸŒ\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return '$field ne doit contenir que des lettres';
    }

    return null;
  }
// Required Field Validator
static String? validateRequired(String? value, {String? fieldName}) {
final field = fieldName ?? 'Ce champ';

if (value == null || value.trim().isEmpty) {
return '$field est requis';
}

return null;
}

// Address Validator
static String? validateAddress(String? value) {
if (value == null || value.isEmpty) {
return 'L\'adresse est requise';
}

if (value.length < 5) {
return 'L\'adresse doit contenir au moins 5 caractères';
}

if (value.length > 200) {
return 'L\'adresse ne doit pas dépasser 200 caractères';
}

return null;
}

// Pharmacy Name Validator
static String? validatePharmacyName(String? value) {
if (value == null || value.isEmpty) {
return 'Le nom de la pharmacie est requis';
}

if (value.length < 3) {
return 'Le nom doit contenir au moins 3 caractères';
}

if (value.length > 100) {
return 'Le nom ne doit pas dépasser 100 caractères';
}

return null;
}

// Authorization Number Validator
static String? validateAuthorizationNumber(String? value) {
if (value == null || value.isEmpty) {
return 'Le numéro d\'autorisation est requis';
}

if (value.length < 5) {
return 'Le numéro d\'autorisation doit contenir au moins 5 caractères';
}

return null;
}

// Medication Name Validator
static String? validateMedicationName(String? value) {
if (value == null || value.isEmpty) {
return 'Le nom du médicament est requis';
}

if (value.length < 2) {
return 'Le nom doit contenir au moins 2 caractères';
}

return null;
}

// Numeric Validator
static String? validateNumeric(String? value, {String? fieldName}) {
final field = fieldName ?? 'Ce champ';

if (value == null || value.isEmpty) {
return '$field est requis';
}

if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
return '$field doit être un nombre';
}

return null;
}

// Positive Number Validator
static String? validatePositiveNumber(String? value, {String? fieldName}) {
final field = fieldName ?? 'Ce champ';

if (value == null || value.isEmpty) {
return '$field est requis';
}

final number = int.tryParse(value);

if (number == null) {
return '$field doit être un nombre';
}

if (number <= 0) {
return '$field doit être positif';
}

return null;
}

// URL Validator
static String? validateUrl(String? value) {
if (value == null || value.isEmpty) {
return 'L\'URL est requise';
}

final urlRegex = RegExp(
r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
);

if (!urlRegex.hasMatch(value)) {
return 'Veuillez entrer une URL valide';
}

return null;
}

// Date Validator
static String? validateDate(String? value) {
if (value == null || value.isEmpty) {
return 'La date est requise';
}

try {
DateTime.parse(value);
return null;
} catch (e) {
return 'Format de date invalide';
}
}

// Future Date Validator
static String? validateFutureDate(DateTime? date) {
if (date == null) {
return 'La date est requise';
}

if (date.isBefore(DateTime.now())) {
return 'La date doit être dans le futur';
}

return null;
}

// Past Date Validator
static String? validatePastDate(DateTime? date) {
if (date == null) {
return 'La date est requise';
}

if (date.isAfter(DateTime.now())) {
return 'La date doit être dans le passé';
}

return null;
}

// Min Length Validator
static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
final field = fieldName ?? 'Ce champ';

if (value == null || value.isEmpty) {
return '$field est requis';
}

if (value.length < minLength) {
return '$field doit contenir au moins $minLength caractères';
}

return null;
}

// Max Length Validator
static String? validateMaxLength(String? value, int maxLength, {String? fieldName}) {
final field = fieldName ?? 'Ce champ';

if (value == null || value.isEmpty) {
return null;
}

if (value.length > maxLength) {
return '$field ne doit pas dépasser $maxLength caractères';
}

return null;
}

// Range Validator
static String? validateRange(String? value, int min, int max, {String? fieldName}) {
final field = fieldName ?? 'Ce champ';

if (value == null || value.isEmpty) {
return '$field est requis';
}

final number = int.tryParse(value);

if (number == null) {
return '$field doit être un nombre';
}

if (number < min || number > max) {
return '$field doit être entre $min et $max';
}

return null;
}

// Multiple Validators Combiner
static String? combineValidators(String? value, List<String? Function(String?)> validators) {
for (final validator in validators) {
final result = validator(value);
if (result != null) {
return result;
}
}
return null;
}
}