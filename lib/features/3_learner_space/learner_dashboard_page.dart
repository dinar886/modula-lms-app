// lib/features/3_learner_space/learner_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/3_learner_space/learner_dashboard_logic.dart';

class LearnerDashboardPage extends StatefulWidget {
  const LearnerDashboardPage({super.key});

  @override
  State<LearnerDashboardPage> createState() => _LearnerDashboardPageState();
}

class _LearnerDashboardPageState extends State<LearnerDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Initialiser le formatage des dates pour la locale française
    initializeDateFormatting('fr_FR', null);
  }

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    // Fournit le BLoC à l'arbre des widgets et charge les données initiales.
    return BlocProvider(
      create: (context) =>
          sl<LearnerDashboardBloc>()..add(FetchLearnerDashboardData(studentId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tableau de Bord'),
          backgroundColor: Colors.grey[50],
          elevation: 0,
        ),
        backgroundColor: Colors.grey[50],
        // Le corps de la page utilise un BlocBuilder pour réagir aux états.
        body: BlocBuilder<LearnerDashboardBloc, LearnerDashboardState>(
          builder: (context, state) {
            if (state is LearnerDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LearnerDashboardError) {
              return Center(child: Text(state.message));
            }
            if (state is LearnerDashboardLoaded) {
              final data = state.data;
              // La page principale est une ListView pour permettre le défilement.
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<LearnerDashboardBloc>().add(
                    FetchLearnerDashboardData(studentId),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Section 1: Reprendre la dernière leçon
                    if (data.lastAccessedLesson != null) ...[
                      _buildLastAccessedCard(context, data.lastAccessedLesson!),
                      const SizedBox(height: 24),
                    ],

                    // Section 2: Prochains devoirs à rendre
                    _buildSectionTitle(context, 'Prochains Devoirs'),
                    const SizedBox(height: 8),
                    if (data.upcomingAssignments.isEmpty)
                      _buildEmptyStateCard(
                        "Aucun devoir à rendre.",
                        "Reposez-vous bien !",
                        Icons.check_circle_outline,
                      )
                    else
                      _buildUpcomingAssignmentsSection(
                        context,
                        data.upcomingAssignments,
                      ),

                    const SizedBox(height: 24),

                    // Section 3 : Cartes d'actions rapides
                    _buildActionsGrid(context),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// Construit la carte pour "Reprendre là où vous vous êtes arrêté".
  Widget _buildLastAccessedCard(
    BuildContext context,
    LastAccessedLessonEntity lesson,
  ) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).primaryColor,
      child: InkWell(
        onTap: () => context.push(
          '/lesson-viewer/${lesson.lessonId}',
          extra: lesson.courseId,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reprendre',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      lesson.lessonTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Cours: ${lesson.courseTitle}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la section des devoirs à venir (max 2)
  Widget _buildUpcomingAssignmentsSection(
    BuildContext context,
    List<UpcomingAssignmentEntity> assignments,
  ) {
    // Limiter à 2 devoirs maximum
    final displayedAssignments = assignments.take(2).toList();

    return Column(
      children: displayedAssignments
          .map(
            (assignment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildModernAssignmentCard(context, assignment),
            ),
          )
          .toList(),
    );
  }

  /// **NOUVEAU WIDGET MODERNE** : Carte de devoir redesignée
  Widget _buildModernAssignmentCard(
    BuildContext context,
    UpcomingAssignmentEntity assignment,
  ) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    // Calcul du temps restant et du statut
    String timeLeftText;
    String dateText;
    Color statusColor;
    IconData statusIcon;
    Color cardBackgroundColor;

    if (assignment.dueDate == null) {
      timeLeftText = 'Sans limite';
      dateText = 'Pas de date limite';
      statusColor = Colors.blue.shade600;
      statusIcon = Icons.all_inclusive;
      cardBackgroundColor = Colors.blue.shade50;
    } else {
      final difference = assignment.dueDate!.difference(now);

      // Formatage de la date - utiliser un format simple si la locale n'est pas disponible
      try {
        dateText = DateFormat(
          'EEEE d MMMM à HH:mm',
          'fr_FR',
        ).format(assignment.dueDate!);
      } catch (e) {
        // Fallback sur un format simple si la locale n'est pas disponible
        dateText = DateFormat('dd/MM/yyyy HH:mm').format(assignment.dueDate!);
      }

      if (difference.isNegative) {
        // En retard
        final daysLate = difference.inDays.abs();
        timeLeftText = daysLate > 0
            ? 'En retard de $daysLate jour${daysLate > 1 ? 's' : ''}'
            : 'En retard';
        statusColor = Colors.red.shade600;
        statusIcon = Icons.error_outline;
        cardBackgroundColor = Colors.red.shade50;
      } else if (difference.inHours < 24) {
        // Moins de 24h
        if (difference.inHours < 1) {
          timeLeftText =
              '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
        } else {
          timeLeftText =
              '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
        }
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.schedule;
        cardBackgroundColor = Colors.orange.shade50;
      } else if (difference.inDays <= 3) {
        // Entre 1 et 3 jours
        timeLeftText =
            '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
        statusColor = Colors.amber.shade700;
        statusIcon = Icons.access_time;
        cardBackgroundColor = Colors.amber.shade50;
      } else {
        // Plus de 3 jours
        timeLeftText = '${difference.inDays} jours';
        statusColor = Colors.green.shade600;
        statusIcon = Icons.event_available;
        cardBackgroundColor = Colors.green.shade50;
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push(
            '/lesson-viewer/${assignment.lessonId}',
            extra: assignment.courseId.toString(),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec badge de statut
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            timeLeftText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Titre de la leçon
                Text(
                  assignment.lessonTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Informations supplémentaires
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        assignment.courseTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit un titre de section standard.
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// Affiche une carte quand une section est vide.
  Widget _buildEmptyStateCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 0,
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Grille d'actions rapides pour la navigation.
  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: <Widget>[
        _buildDashboardCard(
          context,
          icon: Icons.video_library_outlined,
          label: 'Mes Cours',
          onTap: () => context.push('/my-courses'),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.assignment_turned_in_outlined,
          label: 'Mes Rendus',
          onTap: () => context.push('/my-submissions'),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.check_circle_outline,
          label: 'Corrections',
          onTap: () => context.push('/my-corrections'),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.quiz_outlined,
          label: 'Évaluations',
          onTap: () => context.push('/my-evaluations'),
        ),
      ],
    );
  }

  /// Widget réutilisable pour les cartes d'action.
  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 40.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
