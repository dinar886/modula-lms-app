import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/features/1_auth/domain/entities/user_entity.dart';
import 'package:modula_lms/features/1_auth/presentation/bloc/authentication_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/pages/instructor_dashboard_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // On écoute le bloc d'authentification global.
    final userRole = context.watch<AuthenticationBloc>().state.user.role;

    // On affiche le tableau de bord approprié en fonction du rôle.
    switch (userRole) {
      case UserRole.instructor:
        return const InstructorDashboardPage();
      case UserRole.learner:
        return const LearnerDashboardPage();
      default:
        // Cas pour l'utilisateur non connecté ou rôle inconnu.
        return const Center(
          child: Text(
            'Veuillez vous connecter pour voir votre tableau de bord.',
          ),
        );
    }
  }
}

// Un simple placeholder pour le tableau de bord de l'apprenant.
class LearnerDashboardPage extends StatelessWidget {
  const LearnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord')),
      body: const Center(child: Text('Bienvenue sur votre tableau de bord !')),
    );
  }
}
