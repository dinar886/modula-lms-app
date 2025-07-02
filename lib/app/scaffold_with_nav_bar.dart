// lib/app/scaffold_with_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Ce widget est la "coquille" principale de notre application.
// Il contient la barre de navigation inférieure et l'espace pour afficher les pages.
class ScaffoldWithNavBar extends StatelessWidget {
  // Le 'child' est le widget de la page actuelle que go_router nous demande d'afficher.
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Le corps de notre Scaffold est la page actuelle.
      body: child,

      // La barre de navigation inférieure.
      bottomNavigationBar: BottomNavigationBar(
        // 'currentIndex' détermine quel onglet est actuellement sélectionné (et donc surligné).
        currentIndex: _calculateSelectedIndex(context),

        // Style pour les onglets non sélectionnés.
        unselectedItemColor: Colors.grey,
        // Style pour l'onglet sélectionné.
        selectedItemColor: Theme.of(context).primaryColor,

        // Cette fonction est appelée lorsqu'un utilisateur appuie sur un onglet.
        onTap: (int index) {
          // On utilise la méthode 'go' de go_router pour naviguer vers la nouvelle page.
          _onItemTapped(index, context);
        },

        // La liste des onglets à afficher dans la barre.
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: 'Mes Cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // Cette méthode privée détermine l'index de l'onglet sélectionné en fonction de l'URL actuelle.
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/marketplace')) {
      return 0;
    }
    if (location.startsWith('/my-courses')) {
      return 1;
    }
    if (location.startsWith('/dashboard')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    return 0; // Par défaut, on sélectionne le premier onglet.
  }

  // Cette méthode gère la navigation lorsque l'on appuie sur un onglet.
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/marketplace');
        break;
      case 1:
        context.go('/my-courses');
        break;
      case 2:
        context.go('/dashboard');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
