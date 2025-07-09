// lib/features/3_learner_space/my_corrections_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart'; // Pour LessonType
import 'package:modula_lms/features/4_instructor_space/submissions_logic.dart';

class MyCorrectionsPage extends StatelessWidget {
  const MyCorrectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    return BlocProvider(
      create: (context) =>
          sl<SubmissionsBloc>()..add(FetchMySubmissions(studentId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Mes Corrections')),
        body: BlocBuilder<SubmissionsBloc, SubmissionsState>(
          builder: (context, state) {
            if (state is SubmissionsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SubmissionsError) {
              return Center(child: Text(state.message));
            }
            if (state is SubmissionsLoaded) {
              // On filtre la liste pour ne garder que les devoirs notés ('graded')
              final gradedSubmissions = state.submissions
                  .where(
                    (s) =>
                        s.status == 'graded' &&
                        s.lessonType == LessonType.devoir,
                  )
                  .toList();

              if (gradedSubmissions.isEmpty) {
                return const Center(
                  child: Text("Vous n'avez aucune correction pour le moment."),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<SubmissionsBloc>().add(
                    FetchMySubmissions(studentId),
                  );
                },
                child: ListView.builder(
                  itemCount: gradedSubmissions.length,
                  itemBuilder: (context, index) {
                    final submission = gradedSubmissions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          submission.lessonTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Cours: ${submission.courseTitle}'),
                        trailing: _buildGradeChip(submission.grade),
                        onTap: () {
                          // Navigue vers la page de visualisation de la correction
                          context.push(
                            '/graded-submission/${submission.submissionId}',
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // Widget pour afficher la note obtenue.
  Widget _buildGradeChip(double? grade) {
    if (grade != null) {
      return Chip(
        avatar: Icon(Icons.check_circle, color: Colors.white, size: 16),
        label: Text(
          '${grade.toStringAsFixed(1)} / 20',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: grade >= 10 ? Colors.green : Colors.red,
      );
    }
    // Si un devoir "graded" n'a pas de note, on affiche juste "Corrigé"
    return const Chip(
      avatar: Icon(Icons.check, color: Colors.white, size: 16),
      label: Text('Corrigé', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.blue,
    );
  }
}
