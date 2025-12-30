import 'package:flutter/material.dart';
import 'package:pharma/presentation/screens/demandes/liste_demandes_screen.dart';
import '../navigation/bottom_nav_bar.dart';
import '../screens/home/home_screen.dart';
import '../screens/statistiques/statistiques_screen.dart';
import '../screens/profil/profil_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // ✅ MODIFICATION: String? → Map<String, dynamic>?
  Map<String, dynamic>? _demandesFilters;
  Key _demandesKey = UniqueKey();

  void _onNavTap(int index) {
    if (index == 2) {
      // Bouton + : ouvrir la nouvelle demande en modal/nouvelle page
      Navigator.pushNamed(context, '/nouvelle-demande');
      return;
    }

    setState(() {
      _currentIndex = index;
      // ✅ Réinitialiser les filtres quand on navigue normalement vers l'onglet demandes
      if (index == 1) {
        _demandesFilters = null;
        _demandesKey = UniqueKey();
      }
    });
  }

  // ✅ MODIFICATION: Accepter un Map de filtres au lieu d'un String
  void _navigateToDemandesWithFilter(Map<String, dynamic> filters) {
    setState(() {
      _currentIndex = 1; // Aller à l'onglet demandes
      _demandesFilters = filters; // Appliquer les filtres
      _demandesKey = UniqueKey(); // Forcer le rebuild avec nouveaux filtres
    });
  }

  // Construire l'écran actuel à la volée
  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
      // ✅ Passer la méthode de navigation au HomeScreen
        return HomeScreen(
          onNavigateToDemandesWithFilter: _navigateToDemandesWithFilter,
        );
      case 1:
      // ✅ ListeDemandesScreen avec filtres Map et key pour forcer le rebuild
        return ListeDemandesScreen(
          key: _demandesKey,
          initialFilters: _demandesFilters,
        );
      case 3:
        return const StatistiquesScreen();
      case 4:
        return const ProfileScreen();
      default:
        return HomeScreen(
          onNavigateToDemandesWithFilter: _navigateToDemandesWithFilter,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ne garder qu'un seul écran à la fois (pas de cache)
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}