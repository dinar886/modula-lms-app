// lib/features/3_learner_space/learner_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Ce widget représente le tableau de bord principal pour un utilisateur avec le rôle "élève".
class LearnerDashboardPage extends StatelessWidget {
  const LearnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Le titre de la page.
        title: const Text('Tableau de bord Élève'),
      ),
      // On utilise un GridView pour afficher les cartes de manière organisée.
      body: GridView.count(
        crossAxisCount: 2, // Affiche 2 cartes par ligne.
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0, // Espace horizontal entre les cartes.
        mainAxisSpacing: 16.0, // Espace vertical entre les cartes.
        children: <Widget>[
          // Carte 1: Mes Cours
          _buildDashboardCard(
            context,
            icon: Icons.video_library_outlined,
            label: 'Mes Cours',
            // Au clic, navigue vers la page qui liste les cours de l'élève.
            onTap: () => context.push('/my-courses'),
          ),
          // Carte 2: Devoirs / Rendus
          _buildDashboardCard(
            context,
            icon: Icons.assignment_turned_in_outlined,
            label: 'Mes Rendus',
            // MISE A JOUR : Navigue vers la nouvelle page des rendus de l'élève.
            onTap: () => context.push('/my-submissions'),
          ),
          // Carte 3: Corrections
          _buildDashboardCard(
            context,
            icon: Icons.check_circle_outline,
            label: 'Corrections',
            onTap: () {
              // Action temporaire.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'La page "Corrections" est en cours de construction !',
                  ),
                ),
              );
            },
          ),
          // Carte 4: Évaluations
          _buildDashboardCard(
            context,
            icon: Icons.quiz_outlined,
            label: 'Évaluations',
            onTap: () {
              // Action temporaire.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'La page "Évaluations" est en cours de construction !',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget réutilisable pour créer chaque carte du tableau de bord.
  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16.0),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
