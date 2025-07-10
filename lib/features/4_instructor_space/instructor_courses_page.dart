// lib/features/4_instructor_space/instructor_courses_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/3_learner_space/learner_space_logic.dart';

class InstructorCoursesPage extends StatelessWidget {
  const InstructorCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthenticationBloc>().state;
    final instructorId = authState.user.id;
    final userRole = authState.user.role;

    final myCoursesBloc = sl<MyCoursesBloc>()
      ..add(FetchMyCourses(userId: instructorId, role: userRole));

    return BlocProvider.value(
      value: myCoursesBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Cours Créés'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: BlocBuilder<MyCoursesBloc, MyCoursesState>(
          builder: (context, state) {
            if (state is MyCoursesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MyCoursesLoaded) {
              if (state.courses.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Aucun cours créé',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez à partager vos connaissances en créant votre premier cours !',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: () async {
                            final result = await context.push('/create-course');
                            if (result == true) {
                              myCoursesBloc.add(
                                FetchMyCourses(
                                  userId: instructorId,
                                  role: userRole,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Créer mon premier cours'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  myCoursesBloc.add(
                    FetchMyCourses(userId: instructorId, role: userRole),
                  );
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.courses.length,
                  itemBuilder: (context, index) {
                    final course = state.courses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _InstructorCourseCard(
                        course: course,
                        onTap: () async {
                          await context.push('/course-editor', extra: course);
                          myCoursesBloc.add(
                            FetchMyCourses(
                              userId: instructorId,
                              role: userRole,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            }
            if (state is MyCoursesError) {
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
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          myCoursesBloc.add(
                            FetchMyCourses(
                              userId: instructorId,
                              role: userRole,
                            ),
                          );
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await context.push('/create-course');
            if (result == true) {
              myCoursesBloc.add(
                FetchMyCourses(userId: instructorId, role: userRole),
              );
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Créer un cours'),
        ),
      ),
    );
  }
}

// Widget personnalisé pour afficher les cours de l'instructeur
class _InstructorCourseCard extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback onTap;

  const _InstructorCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du cours avec overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        course.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  ),
                  // Badge prix
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.price == 0
                            ? 'Gratuit'
                            : '${course.price.toStringAsFixed(2)} €',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: course.price == 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (course.description != null) ...[
                      Text(
                        course.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Statistiques du cours
                    Row(
                      children: [
                        if (course.enrollmentCount != null) ...[
                          _StatChip(
                            icon: Icons.people_outline,
                            label: '${course.enrollmentCount} inscrits',
                            context: context,
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (course.rating != null) ...[
                          _StatChip(
                            icon: Icons.star,
                            label: course.rating!.toStringAsFixed(1),
                            context: context,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Modifier',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget helper pour les statistiques
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final BuildContext context;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.context,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
