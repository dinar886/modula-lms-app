// lib/features/4_instructor_space/instructor_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_dashboard_logic.dart';

class InstructorDashboardPage extends StatelessWidget {
  const InstructorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupère l'ID de l'instructeur depuis le BLoC d'authentification.
    final instructorId = context.read<AuthenticationBloc>().state.user.id;

    // Utilise BlocProvider pour injecter le BLoC de cette page dans l'arbre des widgets.
    // Le BLoC est créé ici et l'événement pour charger les données est déclenché immédiatement.
    return BlocProvider(
      create: (context) =>
          sl<InstructorDashboardBloc>()
            ..add(FetchInstructorStats(instructorId)),
      child: Scaffold(
        backgroundColor:
            Colors.grey[50], // Un fond légèrement gris pour un look plus doux
        appBar: AppBar(
          title: const Text('Tableau de Bord'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mon Profil',
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: RefreshIndicator(
          // Permet de rafraîchir les données en tirant l'écran vers le bas.
          onRefresh: () async {
            context.read<InstructorDashboardBloc>().add(
              FetchInstructorStats(instructorId),
            );
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            children: [
              // Titre de la section des statistiques.
              Text(
                "Aperçu de votre activité",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Section des statistiques clés.
              _buildStatsSection(),
              const SizedBox(height: 32),
              // Titre de la section des actions rapides.
              Text(
                "Accès Rapide",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionsGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la section qui affiche les statistiques sous forme de grille.
  Widget _buildStatsSection() {
    // BlocBuilder écoute les changements d'état du InstructorDashboardBloc
    // et reconstruit l'interface en conséquence.
    return BlocBuilder<InstructorDashboardBloc, InstructorDashboardState>(
      builder: (context, state) {
        // Affiche un indicateur de chargement pendant la récupération des données.
        if (state is InstructorDashboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // Affiche un message d'erreur si la récupération échoue.
        if (state is InstructorDashboardError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          );
        }
        // Affiche les cartes de statistiques une fois les données chargées.
        if (state is InstructorDashboardLoaded) {
          final stats = state.stats;
          // Formatteur pour afficher les montants en euros.
          final currencyFormatter = NumberFormat.currency(
            locale: 'fr_FR',
            symbol: '€',
          );

          return GridView.count(
            crossAxisCount: 2, // Affiche 2 cartes par ligne
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
                1.5, // Ratio largeur/hauteur pour donner plus d'espace
            children: [
              _StatCard(
                label: 'Revenus (7j)',
                value: currencyFormatter.format(stats.recentRevenue),
                icon: Icons.euro_rounded,
                color1: Colors.green.shade300,
                color2: Colors.green.shade500,
              ),
              _StatCard(
                label: 'Élèves Totaux',
                value: stats.totalStudents.toString(),
                icon: Icons.people_alt_rounded,
                color1: Colors.blue.shade300,
                color2: Colors.blue.shade500,
              ),
              _StatCard(
                label: 'Rendus à corriger',
                value: stats.pendingSubmissions.toString(),
                icon: Icons.hourglass_top_rounded,
                color1: Colors.orange.shade300,
                color2: Colors.orange.shade500,
              ),
              // Vous pouvez ajouter une autre carte ici si nécessaire.
              // Par exemple, une carte pour les nouveaux messages.
              _StatCard(
                label: 'Nouveaux Messages',
                value: "12", // Valeur factice
                icon: Icons.mail_rounded,
                color1: Colors.purple.shade300,
                color2: Colors.purple.shade500,
              ),
            ],
          );
        }
        // Par défaut, retourne un conteneur vide.
        return const SizedBox.shrink();
      },
    );
  }

  /// Construit la grille avec les boutons d'actions rapides.
  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.2, // Ajusté pour un meilleur équilibre visuel
      children: [
        _ActionCard(
          icon: Icons.school_outlined,
          label: 'Gérer mes Cours',
          onTap: () => context.push('/instructor-courses'),
        ),
        _ActionCard(
          icon: Icons.assignment_turned_in_outlined,
          label: 'Voir les Rendus',
          onTap: () => context.push('/submissions'),
        ),
        _ActionCard(
          icon: Icons.group_outlined,
          label: 'Voir mes Élèves',
          onTap: () => context.push('/students'),
        ),
        _ActionCard(
          icon: Icons.add_circle_outline,
          label: 'Créer un Cours',
          onTap: () => context.push('/create-course'),
        ),
      ],
    );
  }
}

/// Widget pour une carte de statistique, maintenant avec un design amélioré.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color1;
  final Color color2;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        // LayoutBuilder permet de rendre les widgets enfants responsifs
        // à la taille du parent, ce qui résout le problème de l'overflow.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: constraints.maxHeight * 0.25,
                  color: Colors.white,
                ),
                const Spacer(),
                // Le texte de la valeur s'adapte pour ne pas déborder.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: constraints.maxHeight * 0.28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                  ),
                ),
                // Le label a une taille de police plus petite.
                Text(
                  label,
                  style: TextStyle(
                    fontSize: constraints.maxHeight * 0.12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget pour une carte d'action rapide avec un design modernisé.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
