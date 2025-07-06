// lib/features/4_instructor_space/presentation/pages/instructor_courses_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/presentation/bloc/authentication_bloc.dart';
import 'package:modula_lms/features/2_marketplace/presentation/widgets/course_card.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_bloc.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_event.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_state.dart';

class InstructorCoursesPage extends StatelessWidget {
  const InstructorCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final instructorId = context.read<AuthenticationBloc>().state.user.id;
    final myCoursesBloc = sl<MyCoursesBloc>()
      ..add(FetchMyCourses(instructorId));

    return BlocProvider.value(
      value: myCoursesBloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Mes Cours')),
        body: BlocBuilder<MyCoursesBloc, MyCoursesState>(
          builder: (context, state) {
            if (state is MyCoursesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MyCoursesLoaded) {
              if (state.courses.isEmpty) {
                return const Center(
                  child: Text(
                    'Vous n\'avez encore créé aucun cours.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              // Ajout du RefreshIndicator ici
              return RefreshIndicator(
                onRefresh: () async {
                  myCoursesBloc.add(FetchMyCourses(instructorId));
                },
                child: ListView.builder(
                  itemCount: state.courses.length,
                  itemBuilder: (context, index) {
                    final course = state.courses[index];
                    return CourseCard(
                      course: course,
                      onTap: () async {
                        // On attend un résultat après la navigation
                        final result = await context.push(
                          '/course-editor',
                          extra: course,
                        );
                        // Si l'éditeur a renvoyé 'true', on rafraîchit
                        if (result == true) {
                          myCoursesBloc.add(FetchMyCourses(instructorId));
                        }
                      },
                    );
                  },
                ),
              );
            }
            if (state is MyCoursesError) {
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // On attend un résultat après la navigation
            final result = await context.push('/create-course');
            // Si la page de création a renvoyé 'true', on rafraîchit
            if (result == true) {
              myCoursesBloc.add(FetchMyCourses(instructorId));
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Créer un cours'),
        ),
      ),
    );
  }
}
