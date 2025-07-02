import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/2_marketplace/presentation/bloc/course_bloc.dart';
import 'package:modula_lms/features/2_marketplace/presentation/bloc/course_event.dart';
import 'package:modula_lms/features/2_marketplace/presentation/bloc/course_state.dart';
import 'package:modula_lms/features/2_marketplace/presentation/widgets/course_card.dart';

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
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
        body: BlocBuilder<CourseBloc, CourseState>(
          builder: (context, state) {
            if (state is CourseLoading || state is CourseInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CourseLoaded) {
              return ListView.builder(
                itemCount: state.courses.length,
                itemBuilder: (context, index) {
                  final course = state.courses[index];
                  // On passe maintenant la logique de navigation via le paramètre onTap.
                  return CourseCard(
                    course: course,
                    onTap: () {
                      // Cette navigation est spécifique à la page du catalogue.
                      context.go('/marketplace/course/${course.id}');
                    },
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
                      onPressed: () {
                        context.read<CourseBloc>().add(FetchCourses());
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Quelque chose s\'est mal passé.'));
          },
        ),
      ),
    );
  }
}
