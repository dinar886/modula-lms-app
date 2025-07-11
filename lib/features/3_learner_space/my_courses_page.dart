// lib/features/3_learner_space/my_courses_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/3_learner_space/learner_space_logic.dart';

class MyCoursesPage extends StatelessWidget {
  final bool purchaseSuccess;

  const MyCoursesPage({super.key, this.purchaseSuccess = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MyCoursesBloc>(),
      child: _MyCoursesView(purchaseSuccess: purchaseSuccess),
    );
  }
}

class _MyCoursesView extends StatefulWidget {
  final bool purchaseSuccess;

  const _MyCoursesView({this.purchaseSuccess = false});

  @override
  State<_MyCoursesView> createState() => _MyCoursesViewState();
}

class _MyCoursesViewState extends State<_MyCoursesView> {
  bool _isVerifyingPurchase = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.user.id;
    final userRole = authState.user.role;

    final myCoursesBloc = context.read<MyCoursesBloc>();

    if (widget.purchaseSuccess) {
      setState(() {
        _isVerifyingPurchase = true;
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          myCoursesBloc.add(FetchMyCourses(userId: userId, role: userRole));
          setState(() {
            _isVerifyingPurchase = false;
          });
        }
      });
    } else {
      myCoursesBloc.add(FetchMyCourses(userId: userId, role: userRole));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.user.id;
    final userRole = authState.user.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Cours'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isVerifyingPurchase
          ? _buildVerifyingPurchaseView()
          : BlocBuilder<MyCoursesBloc, MyCoursesState>(
              builder: (context, state) {
                if (state is MyCoursesLoading || state is MyCoursesInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MyCoursesLoaded) {
                  if (state.courses.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<MyCoursesBloc>().add(
                        FetchMyCourses(userId: userId, role: userRole),
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.courses.length,
                      itemBuilder: (context, index) {
                        final course = state.courses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MyCourseCard(
                            course: course,
                            onTap: () {
                              context.push('/course-player', extra: course);
                            },
                          ),
                        );
                      },
                    ),
                  );
                }

                if (state is MyCoursesError) {
                  return _buildErrorState(state.message);
                }

                return const SizedBox.shrink();
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun cours pour le moment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Explorez notre catalogue pour commencer votre apprentissage !',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/marketplace'),
              icon: const Icon(Icons.explore),
              label: const Text('Explorer le catalogue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.user.id;
    final userRole = authState.user.role;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                context.read<MyCoursesBloc>().add(
                  FetchMyCourses(userId: userId, role: userRole),
                );
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyingPurchaseView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Finalisation de votre inscription...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Cela peut prendre quelques secondes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de carte personnalisé pour les cours de l'utilisateur.
class _MyCourseCard extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback onTap;

  const _MyCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Calcul de la progression
    final total = course.totalLessons ?? 0;
    final completed = course.completedLessons ?? 0;
    final progress = total > 0 ? completed / total : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Image.network(
                    course.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.school,
                        size: 50,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Par ${course.author}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // *** NOUVELLE SECTION DE PROGRESSION ***
                      _buildProgressionSection(
                        context,
                        progress,
                        completed,
                        total,
                      ),
                      const SizedBox(height: 8),
                      // *** NOUVELLE SECTION DES DEVOIRS/CONTRÔLES EN ATTENTE ***
                      _buildPendingWorkSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour la barre de progression
  Widget _buildProgressionSection(
    BuildContext context,
    double progress,
    int completed,
    int total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Progression",
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour les indicateurs de travaux en attente
  Widget _buildPendingWorkSection(BuildContext context) {
    final pendingAssignments = course.pendingAssignments ?? 0;
    final pendingEvaluations = course.pendingEvaluations ?? 0;

    // Si aucun travail n'est en attente, on n'affiche rien.
    if (pendingAssignments == 0 && pendingEvaluations == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (pendingAssignments > 0)
          _StatChip(
            icon: Icons.assignment_late_outlined,
            label: '$pendingAssignments devoir(s)',
            color: Colors.orange.shade700,
          ),
        if (pendingAssignments > 0 && pendingEvaluations > 0)
          const SizedBox(width: 8),
        if (pendingEvaluations > 0)
          _StatChip(
            icon: Icons.assessment_outlined,
            label: '$pendingEvaluations contrôle(s)',
            color: Colors.red.shade700,
          ),
      ],
    );
  }
}

// Widget pour afficher une petite puce d'information (devoir, contrôle)
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
