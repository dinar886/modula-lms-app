// lib/features/3_learner_space/my_courses_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/course_card.dart';
import 'package:modula_lms/features/3_learner_space/learner_space_logic.dart';

class MyCoursesPage extends StatelessWidget {
  const MyCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.user.id;
    final userRole = authState.user.role;

    return BlocProvider(
      create: (context) =>
          sl<MyCoursesBloc>()
            ..add(FetchMyCourses(userId: userId, role: userRole)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Mes Cours')),
        body: BlocBuilder<MyCoursesBloc, MyCoursesState>(
          builder: (context, state) {
            if (state is MyCoursesLoading || state is MyCoursesInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MyCoursesLoaded) {
              if (state.courses.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Vous n\'êtes inscrit à aucun cours pour le moment.\nExplorez notre catalogue pour commencer !',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: state.courses.length,
                itemBuilder: (context, index) {
                  final course = state.courses[index];
                  return CourseCard(
                    course: course,
                    // MODIFICATION : On cache le prix ici.
                    showPrice: false,
                    onTap: () {
                      context.push('/course-player', extra: course);
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
      ),
    );
  }
}
