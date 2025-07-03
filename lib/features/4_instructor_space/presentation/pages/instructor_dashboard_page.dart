import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/presentation/bloc/authentication_bloc.dart';
import 'package:modula_lms/features/2_marketplace/presentation/widgets/course_card.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_bloc.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_event.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_state.dart';

class InstructorDashboardPage extends StatelessWidget {
  const InstructorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final instructorId = context.read<AuthenticationBloc>().state.user.id;

    return BlocProvider(
      create: (context) =>
          sl<MyCoursesBloc>()..add(FetchMyCourses(instructorId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Tableau de Bord Instructeur')),
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
              return ListView.builder(
                itemCount: state.courses.length,
                itemBuilder: (context, index) {
                  final course = state.courses[index];
                  return CourseCard(
                    course: course,
                    onTap: () {
                      // **CORRECTION** : Utilisation de `push` pour aller à l'éditeur.
                      context.push('/course-editor', extra: course);
                    },
                  );
                },
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
          onPressed: () {
            // **CORRECTION** : Utilisation de `push` pour aller à la page de création.
            context.push('/create-course');
          },
          icon: const Icon(Icons.add),
          label: const Text('Créer un cours'),
        ),
      ),
    );
  }
}
