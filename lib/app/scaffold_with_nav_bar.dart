// lib/app/scaffold_with_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';

/// Un Scaffold qui inclut une barre de navigation persistante.
/// Utilisé par GoRouter pour les routes principales de l'application.
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  /// Calcule l'index de navigation actuel à partir de la route.
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    // On récupère le rôle de l'utilisateur pour ajuster la logique.
    final userRole = context.read<AuthenticationBloc>().state.user.role;

    if (location.startsWith('/marketplace')) return 0;
    // Si l'utilisateur est un élève :
    if (userRole == UserRole.learner) {
      if (location.startsWith('/my-courses')) return 1;
      if (location.startsWith('/dashboard')) return 2;
      if (location.startsWith('/profile')) return 3;
    } else {
      // Si l'utilisateur est un instructeur :
      if (location.startsWith('/dashboard')) return 1;
      if (location.startsWith('/profile')) return 2;
    }
    return 0; // Par défaut, on retourne sur le catalogue.
  }

  /// Gère la navigation lors du clic sur un onglet.
  void _onItemTapped(int index, BuildContext context) {
    final userRole = context.read<AuthenticationBloc>().state.user.role;

    // Logique de navigation pour un élève
    if (userRole == UserRole.learner) {
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
    } else {
      // Logique de navigation pour un instructeur
      switch (index) {
        case 0:
          context.go('/marketplace');
          break;
        case 1:
          context.go('/dashboard');
          break;
        case 2:
          context.go('/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // On récupère le rôle pour construire la liste des onglets.
    final userRole = context.watch<AuthenticationBloc>().state.user.role;

    // On définit la liste des onglets qui seront affichés.
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        label: 'Catalogue',
        activeIcon: Icon(Icons.store),
      ),
      // On ajoute l'onglet "Mes Cours" seulement si l'utilisateur est un élève.
      if (userRole == UserRole.learner)
        const BottomNavigationBarItem(
          icon: Icon(Icons.video_library_outlined),
          label: 'Mes Cours',
          activeIcon: Icon(Icons.video_library),
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Tableau de bord',
        activeIcon: Icon(Icons.dashboard),
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profil',
        activeIcon: Icon(Icons.person),
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        // Style pour la barre de navigation
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
