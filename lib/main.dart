import 'package:flutter/material.dart';
import 'package:pharma/data/providers/dashboard_provider.dart';
import 'package:pharma/data/providers/medicine_provider.dart';
import 'package:pharma/data/providers/stats_provider.dart';
import 'package:pharma/data/providers/pharmacie_provider.dart';
import 'package:pharma/repositories/dashboard_repository.dart';
import 'package:pharma/repositories/medecine_repository.dart';
import 'package:pharma/repositories/stats_repository.dart';
import 'package:pharma/repositories/pharmacie_repository.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Config
import 'config/routes.dart';
import 'config/theme.dart';

// Core Services
import 'core/services/storage_service.dart';
import 'core/network/api_client.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';

// Repositories
import 'repositories/auth_repository.dart';
import 'repositories/demande_repository.dart';
import 'repositories/patient_repository.dart';
import 'repositories/medicament_repository.dart';

// Providers
import 'data/providers/auth_provider.dart';
import 'data/providers/demande_provider.dart';

// Constants
import 'shared/constants/colors.dart';

// Variables globales pour les services
late StorageService storageService;
late ApiService apiService;
late AuthService authService;
late AuthRepository authRepository;
late DemandeRepository demandeRepository;
late PatientRepository patientRepository;
late MedicamentRepository medicamentRepository;
late MedicineRepository medicineRepository;
late StatsRepository statsRepository;
late PharmacieRepository pharmacieRepository;
late AuthProvider authProvider;
late DemandeProvider demandeProvider;
late MedicineProvider medicineProvider;
late DashboardRepository dashboardRepository;
late DashboardProvider dashboardProvider;
late StatsProvider statsProvider;
late PharmacieProvider pharmacieProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // ============ INITIALIZE SERVICES ============

  // 1. Initialize StorageService
  storageService = StorageService();
  await storageService.init();

  // 2. Initialize ApiClient with StorageService
  ApiClient.init(storageService);

  // 3. Create ApiService
  apiService = ApiService();

  // 4. Create AuthService
  authService = AuthService(
    apiService: apiService,
    storageService: storageService,
  );

  // ============ INITIALIZE REPOSITORIES ============

  // 5. Create Repositories
  authRepository = AuthRepository(authService: authService);
  demandeRepository = DemandeRepository(apiService: apiService);
  patientRepository = PatientRepository(apiService: apiService);
  medicamentRepository = MedicamentRepository(apiService: apiService);
  medicineRepository = MedicineRepository(apiService: apiService);
  dashboardRepository = DashboardRepository(apiService: apiService);
  statsRepository = StatsRepository();  // ← Nouveau
  pharmacieRepository = PharmacieRepository();  // ← Nouveau

  // ============ INITIALIZE PROVIDERS ============

  // 6. Create Providers
  authProvider = AuthProvider(authRepository: authRepository);

  demandeProvider = DemandeProvider(
    demandeRepository: demandeRepository,
    patientRepository: patientRepository,
    medicamentRepository: medicamentRepository,
  );

  medicineProvider = MedicineProvider(
    medicineRepository: medicineRepository,
  );

  dashboardProvider = DashboardProvider(
    dashboardRepository: dashboardRepository,
  );

  statsProvider = StatsProvider();  // ← Nouveau

  pharmacieProvider = PharmacieProvider();  // ← Nouveau

  // ============ RUN APP ============
  runApp(const PharmaAlerteApp());
}

class PharmaAlerteApp extends StatelessWidget {
  const PharmaAlerteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ========== CORE SERVICES ==========
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),

        // ========== REPOSITORIES ==========
        Provider<AuthRepository>.value(value: authRepository),
        Provider<DemandeRepository>.value(value: demandeRepository),
        Provider<PatientRepository>.value(value: patientRepository),
        Provider<MedicamentRepository>.value(value: medicamentRepository),
        Provider<MedicineRepository>.value(value: medicineRepository),
        Provider<DashboardRepository>.value(value: dashboardRepository),
        Provider<StatsRepository>.value(value: statsRepository),  // ← Nouveau
        Provider<PharmacieRepository>.value(value: pharmacieRepository),  // ← Nouveau

        // ========== PROVIDERS ==========
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DemandeProvider>.value(value: demandeProvider),
        ChangeNotifierProvider<MedicineProvider>.value(value: medicineProvider),
        ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
        ChangeNotifierProvider<StatsProvider>.value(value: statsProvider),  // ← Nouveau
        ChangeNotifierProvider<PharmacieProvider>.value(value: pharmacieProvider),  // ← Nouveau
      ],
      child: MaterialApp(
        title: 'Pharma Alerte',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}

// Écran de démarrage (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingMessage = 'Initialisation...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Étape 1: Petit délai pour afficher le splash
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Étape 2: Charger les médicaments depuis le cache
      setState(() {
        _loadingMessage = 'Chargement des médicaments...';
      });

      final medicineProvider = context.read<MedicineProvider>();

      // Charger d'abord depuis le cache (rapide)
      await medicineProvider.loadFromCache();

      debugPrint('Médicaments en cache: ${medicineProvider.count}');

      // Puis charger depuis l'API en arrière-plan
      medicineProvider.loadMedicines().then((_) {
        debugPrint('Médicaments chargés depuis l\'API: ${medicineProvider.count}');
      }).catchError((e) {
        debugPrint('Erreur chargement API: $e');
        // Si erreur API mais cache disponible, continuer quand même
      });

      if (!mounted) return;

      // Étape 3: Vérifier l'authentification
      setState(() {
       // _loadingMessage = 'Vérification de la session...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = await authProvider.checkAuthStatus();

      if (!mounted) return;

      // Étape 4: Naviguer vers l'écran approprié
      if (isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // En cas d'erreur critique
      debugPrint('❌ Erreur critique: $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });

      // Attendre 2 secondes puis rediriger vers login
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'images/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Pharma Alerte',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Gestion des ruptures de stock',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 50),

            // Afficher erreur ou chargement
            if (_hasError) ...[
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage ?? 'Erreur d\'initialisation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Redirection en cours...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else ...[
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _loadingMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              // Optionnel: Afficher le nombre de médicaments chargés
              const SizedBox(height: 8),
              Consumer<MedicineProvider>(
                builder: (context, provider, _) {
                  if (provider.count > 0) {
                    return Text(
                      '${provider.count} médicaments disponibles',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}