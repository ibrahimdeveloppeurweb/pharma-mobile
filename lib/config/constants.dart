class AppConstants {
  // App Info
  static const String appName = 'Pharma Alerte';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API
  static const String apiBaseUrl = 'https://pharmaalerte.net';
  //static const String apiBaseUrl = 'http://10.0.2.2:8001';
  static const BASE_URL = '$apiBaseUrl/api/v1';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  //   theo1

  // AWS Textract
  static const String awsRegion = 'us-east-1';
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];

  // SMS
  static const String smsProvider = 'twilio';
  static const int smsMaxLength = 160;

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxItemsPerPage = 50;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String pharmacieDataKey = 'pharmacie_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Regex Patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[0-9]{10,15}$';
  static const String passwordPattern =
      r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$';

  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Snackbar Duration
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration snackbarLongDuration = Duration(seconds: 5);

  // Debounce Duration
  static const Duration debounceDuration = Duration(milliseconds: 500);

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 24);
  static const Duration shortCacheDuration = Duration(hours: 1);

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedFileTypes = [
    'image/jpeg',
    'image/png',
    'application/pdf'
  ];

  // Statuts Demande
  static const String statutEnAttente = 'en_attente';
  static const String statutAlerte = 'alerte';
  static const String statutRecupere = 'recupere';
  static const String statutAnnule = 'annule';

  // Roles
  static const String roleAdmin = 'admin';
  static const String rolePharmacien = 'pharmacien';
  static const String roleAssistant = 'assistant';

  // Messages
  static const String msgSuccessLogin = 'Connexion réussie';
  static const String msgSuccessRegister = 'Inscription réussie';
  static const String msgSuccessLogout = 'Déconnexion réussie';
  static const String msgSuccessSave = 'Enregistrement réussi';
  static const String msgSuccessUpdate = 'Modification réussie';
  static const String msgSuccessDelete = 'Suppression réussie';
  static const String msgSuccessSMS = 'SMS envoyé avec succès';

  static const String msgErrorGeneral = 'Une erreur est survenue';
  static const String msgErrorNetwork = 'Erreur de connexion';
  static const String msgErrorAuth = 'Erreur d\'authentification';
  static const String msgErrorInvalidCredentials = 'Identifiants invalides';
  static const String msgErrorRequired = 'Ce champ est requis';
  static const String msgErrorInvalidEmail = 'Email invalide';
  static const String msgErrorInvalidPhone = 'Numéro de téléphone invalide';
  static const String msgErrorPasswordTooShort =
      'Le mot de passe doit contenir au moins 8 caractères';
  static const String msgErrorPasswordMismatch =
      'Les mots de passe ne correspondent pas';

  // Placeholders
  static const String placeholderEmail = 'exemple@email.com';
  static const String placeholderPhone = '06 12 34 56 78';
  static const String placeholderPassword = '••••••••';
  static const String placeholderSearch = 'Rechercher...';

  // Support
  static const String supportEmail = 'support@pharma-alerte.com';
  static const String supportPhone = '+212 5 22 34 56 78';
  static const String websiteUrl = 'https://pharma-alerte.com';

  // Social Links
  static const String facebookUrl = 'https://facebook.com/pharmaalerte';
  static const String twitterUrl = 'https://twitter.com/pharmaalerte';
  static const String linkedinUrl = 'https://linkedin.com/company/pharmaalerte';

  // Legal
  static const String privacyPolicyUrl = 'https://pharma-alerte.com/privacy';
  static const String termsOfServiceUrl = 'https://pharma-alerte.com/terms';

  // Feature Flags
  static const bool enableBiometric = true;
  static const bool enablePushNotifications = true;
  static const bool enableDarkMode = false;
  static const bool enableMultiLanguage = false;
  static const bool enableAnalytics = true;
}

// Enums
enum StatutDemande {
  enAttente,
  alerte,
  recupere,
  annule,
}

enum UserRole {
  admin,
  pharmacien,
  assistant,
}

enum RequestStatus {
  idle,
  loading,
  success,
  error,
}


class ApiEndPoints  {
  static const authLogoutEndPoint = 'auth/logout';
  static const authEditPasswordEndPoint = 'auth/edit/password';
  static const authTokenRefreshEndPoint = 'auth/token/refresh';
  static const medicamentPublicGetEndpoint = 'secure/medecine';
  static const pharmacieDemandeGetEndpoint = 'secure/pharmacie/demande';
  static const villeEndPoint = 'secure/ville';
  static const communeEndPoint = 'secure/commune';
  static const categoryEndPoint = 'secure/category';
  static const createPharmacieEndPoint = 'public/pharmacie/new';
  static const createpharmacieDemandeGetEndpoint = "/${pharmacieDemandeGetEndpoint}/new";
  static const pharmacieDemandeStatsGetEndpoint = "/${pharmacieDemandeGetEndpoint}/statistics";
  static const dashboardEndpoint = 'secure/pharmacie/dashboard';


  static const pharmaciesEndpoint = 'secure/pharmacie'; // toutes pharmaacies recuperer au niveau admin
  static const pharmaciesStatsEndpoint = 'secure/pharmacie/statistics'; // toutes pharmaacies recuperer au niveau admin





  static const paysEndpoint = 'pays';
  static const regionEndpoint = 'region';
  static const zoneEndpoint = 'zone';
  static const situationmatEndpoint = 'situationmat';
  static const siteEndpoint = 'site';
  static const groupeTaxeEndpoint = 'groupeTaxe';
  static const taxeEndpoint = 'taxes';
  static const compteEndpoint = 'compte';
  static const communeEndpoint = 'commune';
  static const alerteEndPoint = 'secure/alerte';
  static const alerteReseauEndPoint = 'secure/alerte-reseau';
  static const infrastructureEndPoint = 'secure/infrastructure';
  static const acteEndPoint = 'secure/actes';
  static const equipementEndPoint = 'secure/equipement';
  static const degradationEndPoint = 'secure/degradation';
  static const rapportEndPoint = 'secure/rapport';
  static const civiliteEndpoint = 'civilite';
  static const categorieEndpoint = 'secure/category';
  static const periodeEndpoint = 'periode';
  static const typeActiviteEndpoint = 'activite';
  static const clientTaxeEndpoint = 'clientaxe';
  static const paiementEndpoint = 'paiement';
  static const associationEndpoint = 'association';
  static const typeClientEndpoint = 'typeclient';

  static const operationEndpoint = 'operation';
  static const recouvrementEndpoint = 'recouvrement';


}

class EndPointKeys {
  static const loginEndPointKey = 'login';
  static const registerEndPointKey = 'register';
  static const getDetailEndPointKey = 'get-detail';

  static const getListEndPointKey = 'get-list';

  static const forgetPwdEndPointKey = 'forgot-password';


  static const alltEndPointKey = 'all';
  static const saveEndPointKey = 'new';
  static const editEndPointKey = 'edit';
  static const filterEndPointKey = 'filter';
  static const assignEndPointKey = 'assign';
  static const showEndPointKey = 'show';

  static const updateProfileEndPointKey = 'profile-update';
  static const getAppointmentEndPointKey = 'get-appointment';

  static const changePwdEndPointKey = 'change-password';

  static const deleteEndPointKey = 'delete';
  static const createEndPointKey = 'create';
  static const updateEndPointKey = 'update';
  static const getByCriteriaEndPointKey = 'getByCriteria';

  static const getClientDetailsEndPoinKey = "rechercheClient";
}