// lib/features/2_marketplace/marketplace_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
// **CORRECTION : On importe notre nouveau CourseCard**
import 'package:modula_lms/features/2_marketplace/course_card.dart';
import 'marketplace_logic.dart';

//==============================================================================
// PAGE LISTE DES COURS
//==============================================================================
class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CourseBloc>()..add(FetchCourses()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catalogue des Cours'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: BlocBuilder<CourseBloc, CourseState>(
          builder: (context, state) {
            if (state is CourseLoading || state is CourseInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CourseListLoaded) {
              if (state.courses.isEmpty) {
                return const Center(child: Text("Aucun cours disponible."));
              }
              return ListView.builder(
                itemCount: state.courses.length,
                itemBuilder: (context, index) {
                  final course = state.courses[index];
                  // On utilise notre widget public CourseCard
                  return CourseCard(
                    course: course,
                    onTap: () =>
                        context.push('/marketplace/course/${course.id}'),
                  );
                },
              );
            }
            if (state is CourseError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () =>
                          context.read<CourseBloc>().add(FetchCourses()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('État non géré.'));
          },
        ),
      ),
    );
  }
}

//==============================================================================
// PAGE DÉTAIL D'UN COURS
//==============================================================================
class CourseDetailPage extends StatelessWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CourseDetailBloc>()..add(FetchCourseDetails(courseId)),
      child: Scaffold(
        body: BlocBuilder<CourseDetailBloc, CourseState>(
          builder: (context, state) {
            if (state is CourseLoading || state is CourseInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CourseDetailLoaded) {
              final course = state.course;
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 250.0,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        course.title,
                        style: const TextStyle(fontSize: 16),
                      ),
                      background: Image.network(
                        course.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Par ${course.author}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            course.description ?? 'Aucune description.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                /* Logique d'achat */
                              },
                              child: Text(
                                'Acheter pour ${course.price.toStringAsFixed(2)} €',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            if (state is CourseError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
// Le widget _CourseCard a été supprimé d'ici.