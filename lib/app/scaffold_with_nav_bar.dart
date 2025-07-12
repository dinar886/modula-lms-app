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
    final userRole = context.read<AuthenticationBloc>().state.user.role;

    // --- MISE À JOUR DE LA LOGIQUE D'INDEXATION ---
    if (location.startsWith('/marketplace')) return 0;

    if (userRole == UserRole.learner) {
      if (location.startsWith('/my-courses')) return 1;
      if (location.startsWith('/dashboard')) return 2;
      if (location.startsWith('/messaging')) return 3; // Nouvel onglet
    } else {
      // Instructor
      if (location.startsWith('/dashboard')) return 1;
      if (location.startsWith('/messaging')) return 2; // Nouvel onglet
    }
    return 0; // Par défaut sur le catalogue
  }

  /// Gère la navigation lors du clic sur un onglet.
  void _onItemTapped(int index, BuildContext context) {
    final userRole = context.read<AuthenticationBloc>().state.user.role;

    // --- MISE À JOUR DE LA LOGIQUE DE NAVIGATION ---
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
          context.go('/messaging'); // Navigation vers la messagerie
          break;
      }
    } else {
      // Instructor
      switch (index) {
        case 0:
          context.go('/marketplace');
          break;
        case 1:
          context.go('/dashboard');
          break;
        case 2:
          context.go('/messaging'); // Navigation vers la messagerie
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthenticationBloc>().state.user.role;

    // --- MISE À JOUR DES ÉLÉMENTS DE LA BARRE DE NAVIGATION ---
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        label: 'Catalogue',
        activeIcon: Icon(Icons.store),
      ),
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
      // Remplacement de "Profil" par "Messagerie"
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Messages',
        activeIcon: Icon(Icons.chat_bubble),
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
