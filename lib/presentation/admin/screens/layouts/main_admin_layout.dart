import 'package:flutter/material.dart';
import 'package:pharma/config/routes.dart';
import 'package:pharma/presentation/admin/navigation/admin_bottom_nav_bar.dart';
import 'package:pharma/presentation/admin/screens/ajour_pharmace_admin_screen.dart';
import 'package:pharma/presentation/admin/screens/home_admin_screen.dart';
import 'package:pharma/presentation/admin/screens/liste_pharmacie_screen.dart';
import 'package:pharma/presentation/admin/screens/profile_admin_screen.dart';
import 'package:pharma/presentation/admin/screens/statistiques_pharmacie_screen.dart';
import 'package:pharma/presentation/screens/profil/profil_screen.dart';


class MainLayoutAdmin extends StatefulWidget {
  const MainLayoutAdmin({Key? key}) : super(key: key);

  @override
  State<MainLayoutAdmin> createState() => _MainLayoutAdminState();
}

class _MainLayoutAdminState extends State<MainLayoutAdmin> {
  int _currentIndex = 0;

  // 🎯 Variables pour gérer le filtre des demandes (pour l'admin)
  String? _demandesStatut;
  Key _demandesKey = UniqueKey();

  void _onNavTap(int index) {
    // Si l'admin a aussi un bouton central spécial (optionnel)
    if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.ajoutPharmaacieAdmin);
      return;
    }

    setState(() {
      _currentIndex = index;
      // 🎯 Réinitialiser le filtre quand on navigue vers l'onglet demandes
      if (index == 1) {
        _demandesStatut = null;
        _demandesKey = UniqueKey();
      }
    });
  }

  // 🎯 Méthode appelée depuis HomeAdminScreen pour naviguer vers demandes avec filtre
  void _navigateToDemandesWithFilter(String statut) {
    setState(() {
      _currentIndex = 1; // Aller à l'onglet gestion des demandes
      _demandesStatut = statut; // Appliquer le filtre
      _demandesKey = UniqueKey(); // Forcer le rebuild avec nouveau statut
    });
  }

  // Construire l'écran actuel à la volée
  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
      // 🎯 Dashboard admin avec navigation vers demandes filtrées
        return HomeAdminScreen(
          onNavigateToDemandesWithFilter: _navigateToDemandesWithFilter,
        );
      case 1:
      // 🎯 Gestion des demandes (toutes les demandes pour l'admin)
        return PharmacieAdminScreen(
          key: _demandesKey,
          statut: _demandesStatut,
        );
      case 3:
      // 🎯 Gestion des utilisateurs (pharmacies, validateurs, etc.)
        return const StatistiqueAdminScreen();
      case 4:
      // 🎯 Gestion des utilisateurs (pharmacies, validateurs, etc.)
        return const ProfileAdminScreen();

      default:
        return HomeAdminScreen(
          onNavigateToDemandesWithFilter: _navigateToDemandesWithFilter,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // L'écran actuel sans cache
      body: _getCurrentScreen(),
      // Bottom navigation bar spécifique admin
      bottomNavigationBar: BottomNavBarAdmin(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ✅ Navigation admin avec bottom bar toujours visible
// Les écrans admin sont : Dashboard, Demandes, Utilisateurs, Statistiques, Profil