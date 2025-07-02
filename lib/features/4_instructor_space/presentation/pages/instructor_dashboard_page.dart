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
    // On récupère l'ID de l'instructeur connecté.
    final instructorId = context.read<AuthenticationBloc>().state.user.id;

    // On fournit le MyCoursesBloc à cette page. Même si le nom est "MyCourses",
    // la logique est la même : récupérer les cours liés à un user_id.
    return BlocProvider(
      create: (context) =>
          sl<MyCoursesBloc>()..add(FetchMyCourses(instructorId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Tableau de Bord Instructeur')),
        // Le BlocBuilder va reconstruire l'interface en fonction de l'état.
        body: BlocBuilder<MyCoursesBloc, MyCoursesState>(
          builder: (context, state) {
            // Pendant le chargement, on affiche un indicateur.
            if (state is MyCoursesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Quand les cours sont chargés.
            if (state is MyCoursesLoaded) {
              // Si la liste est vide.
              if (state.courses.isEmpty) {
                return const Center(
                  child: Text(
                    'Vous n\'avez encore créé aucun cours.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              // Sinon, on affiche la liste des cours.
              return ListView.builder(
                itemCount: state.courses.length,
                itemBuilder: (context, index) {
                  final course = state.courses[index];
                  // On utilise le même CourseCard, mais la navigation sera différente.
                  return CourseCard(
                    course: course,
                    onTap: () {
                      // On navigue vers la page d'édition du cours.
                      context.go('/course-editor', extra: course);
                    },
                  );
                },
              );
            }
            // En cas d'erreur.
            if (state is MyCoursesError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            // État par défaut.
            return const SizedBox.shrink();
          },
        ),
        // On déplace le bouton de création dans un FloatingActionButton, c'est plus standard.
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.go('/create-course');
          },
          icon: const Icon(Icons.add),
          label: const Text('Créer un cours'),
        ),
      ),
    );
  }
}
