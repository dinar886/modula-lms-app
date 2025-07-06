// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/3_learner_space/learner_dashboard_page.dart'; // Importez la nouvelle page.
import 'package:modula_lms/features/4_instructor_space/instructor_dashboard_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // On lit le rôle de l'utilisateur à partir du bloc d'authentification.
    final userRole = context.watch<AuthenticationBloc>().state.user.role;

    // On affiche le tableau de bord correspondant au rôle.
    switch (userRole) {
      case UserRole.instructor:
        // Pour les instructeurs, on affiche leur tableau de bord.
        return const InstructorDashboardPage();
      case UserRole.learner:
        // MISE À JOUR : Pour les élèves, on affiche maintenant leur nouveau tableau de bord.
        return const LearnerDashboardPage();
      default:
        // Par défaut, si l'utilisateur n'est pas connecté ou que son rôle est inconnu.
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Veuillez vous connecter pour voir votre tableau de bord.',
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}
