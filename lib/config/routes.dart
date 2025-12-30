import 'package:flutter/material.dart';
import 'package:pharma/data/providers/auth_provider.dart';
import 'package:pharma/presentation/admin/screens/ajour_pharmace_admin_screen.dart';
import 'package:pharma/presentation/admin/screens/layouts/main_admin_layout.dart';
import 'package:pharma/presentation/screens/auth/forgot_password_screen.dart';
import 'package:provider/provider.dart';
import '../presentation/layouts/main_layout.dart';  // ← Ajoutez cet import
import '../presentation/screens/auth/connexion_screen.dart';
import '../presentation/screens/auth/inscription_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/demandes/nouvelle_demande_screen.dart';
import '../presentation/screens/demandes/liste_demandes_screen.dart';
import '../presentation/screens/demandes/detail_demande_screen.dart';
import '../presentation/screens/statistiques/statistiques_screen.dart';
import '../presentation/screens/profil/profil_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String nouvelleDemande = '/nouvelle-demande';
  static const String demandes = '/demandes';
  static const String detailDemande = '/demandes/detail';
  static const String statistiques = '/statistiques';
  static const String profil = '/profil';
  static const String editProfil = '/profil/edit';
  static const String settings = '/settings';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsSMS = '/settings/sms';
  static const String settingsTextract = '/settings/textract';
  static const String help = '/help';


  static const String homeAdmin = '/home-admin';
  static const String pharmaacieAdmin = '/pharmacie-admin';
  static const String statsdmin = '/stats-admin';
  static const String profiledmin = '/profile-admin';
  static const String ajoutPharmaacieAdmin = '/ajout-pharmacie-admin';


  // Routes map
  static Map<String, WidgetBuilder> routes = {
    login: (context) => const ConnexionScreen(),
    register: (context) => const InscriptionScreen(),
    //home: (context) => const MainLayout(),  // ← Changez ici (était HomeScreen)
    home: (context) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      print("rôle de l'utilisateur ${user?.role}");
      // Vérifier le type/rôle de l'utilisateur
      if (user?.role == 'SUPER_ADMIN') {
        return const MainLayoutAdmin();
      } else {
        //return const  MainLayout();
        return const MainLayout();
      }
    },

    nouvelleDemande: (context) => const NouvelleDemandeScreen(),
    demandes: (context) =>  ListeDemandesScreen(),
    statistiques: (context) => const StatistiquesScreen(),
    profil: (context) => const ProfileScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),

    //admin
    ajoutPharmaacieAdmin: (context) => const NouvelleDemandeScreen(),
    ajoutPharmaacieAdmin: (context) => const CreatePharmacieAdminScreen(),
  };

  // Generate route for dynamic routes
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle detail demande route with ID parameter



    // Return null for unhandled routes (will show error screen)
    return null;
  }

  // Navigation helpers
  static void goToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  static void goToRegister(BuildContext context) {
    Navigator.pushNamed(context, register);
  }

  static void goToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, home);
  }

  static void goToNouvelleDemande(BuildContext context) {
    Navigator.pushNamed(context, nouvelleDemande);
  }

  static void goToAjoutPharmacie(BuildContext context) {
    Navigator.pushNamed(context, ajoutPharmaacieAdmin);
  }

  static void goToListeDemandes(BuildContext context) {
    Navigator.pushNamed(context, demandes);
  }

  static void goToDetailDemande(BuildContext context, String demandeId) {
    Navigator.pushNamed(
      context,
      detailDemande,
      arguments: {'id': demandeId},
    );
  }

  static void goToStatistiques(BuildContext context) {
    Navigator.pushNamed(context, statistiques);
  }

  static void goToProfil(BuildContext context) {
    Navigator.pushNamed(context, profil);
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}