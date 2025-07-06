// lib/features/4_instructor_space/instructor_courses_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/course_card.dart';
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
        appBar: AppBar(title: const Text('Mes Cours Créés')),
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
              return RefreshIndicator(
                onRefresh: () async {
                  myCoursesBloc.add(
                    FetchMyCourses(userId: instructorId, role: userRole),
                  );
                },
                child: ListView.builder(
                  itemCount: state.courses.length,
                  itemBuilder: (context, index) {
                    final course = state.courses[index];
                    return CourseCard(
                      course: course,
                      // MODIFICATION : On cache également le prix ici.
                      showPrice: false,
                      onTap: () async {
                        await context.push('/course-editor', extra: course);
                        myCoursesBloc.add(
                          FetchMyCourses(userId: instructorId, role: userRole),
                        );
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
