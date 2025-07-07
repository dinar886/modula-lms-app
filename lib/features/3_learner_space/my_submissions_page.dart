// lib/features/3_learner_space/my_submissions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/4_instructor_space/submissions_logic.dart';

class MySubmissionsPage extends StatelessWidget {
  const MySubmissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    return BlocProvider(
      create: (context) =>
          sl<SubmissionsBloc>()..add(FetchMySubmissions(studentId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Mes Rendus')),
        body: BlocBuilder<SubmissionsBloc, SubmissionsState>(
          builder: (context, state) {
            if (state is SubmissionsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SubmissionsError) {
              return Center(child: Text(state.message));
            }
            if (state is SubmissionsLoaded) {
              if (state.submissions.isEmpty) {
                return const Center(
                  child: Text("Vous n'avez encore rien rendu."),
                );
              }
              return ListView.builder(
                itemCount: state.submissions.length,
                itemBuilder: (context, index) {
                  final submission = state.submissions[index];
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
                      trailing: _buildGradeChip(
                        submission.status,
                        submission.grade,
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildGradeChip(String status, double? grade) {
    if (status == 'submitted') {
      return const Chip(
        label: Text('En attente'),
        backgroundColor: Colors.grey,
      );
    }
    if (grade != null) {
      return Chip(
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
    return const Chip(label: Text('Noté'));
  }
}
