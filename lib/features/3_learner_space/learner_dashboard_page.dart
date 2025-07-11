// lib/features/3_learner_space/learner_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/3_learner_space/learner_dashboard_logic.dart';
import 'package:modula_lms/features/4_instructor_space/submissions_logic.dart';

class LearnerDashboardPage extends StatelessWidget {
  const LearnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    // Fournit le BLoC à l'arbre des widgets et charge les données initiales.
    return BlocProvider(
      create: (context) =>
          sl<LearnerDashboardBloc>()..add(FetchLearnerDashboardData(studentId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Tableau de Bord')),
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
                      const Text(
                        "Aucun devoir à rendre prochainement. Reposez-vous bien !",
                      )
                    else
                      ...data.upcomingAssignments.map(
                        (submission) =>
                            _buildAssignmentCard(context, submission),
                      ),

                    const SizedBox(height: 24),

                    // Section 3: MISE A JOUR - La section des dernières notes a été supprimée.

                    // Section 4 : Cartes d'actions rapides (comme avant)
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

  /// Construit une carte pour un devoir à rendre.
  Widget _buildAssignmentCard(
    BuildContext context,
    SubmissionSummaryEntity submission,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(
          Icons.assignment_late_outlined,
          color: Colors.orange,
        ),
        title: Text(
          submission.lessonTitle,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'À rendre avant le ${DateFormat('dd/MM/yyyy HH:mm').format(submission.submissionDate)}',
        ),
        onTap: () => context.push(
          '/lesson-viewer/${submission.lessonId}',
          extra: submission.courseId.toString(),
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
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
