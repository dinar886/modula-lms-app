// lib/features/4_instructor_space/submissions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart'; // Pour LessonType
import 'package:modula_lms/features/4_instructor_space/submissions_logic.dart';

class SubmissionsPage extends StatelessWidget {
  const SubmissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final instructorId = context.read<AuthenticationBloc>().state.user.id;

    return BlocProvider(
      create: (context) =>
          sl<SubmissionsBloc>()..add(FetchInstructorSubmissions(instructorId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Rendus des Élèves')),
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
                  child: Text("Aucun élève n'a encore rendu de travail."),
                );
              }
              return ListView.builder(
                itemCount: state.submissions.length,
                itemBuilder: (context, index) {
                  final submission = state.submissions[index];
                  return SubmissionCard(submission: submission);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class SubmissionCard extends StatelessWidget {
  final SubmissionSummaryEntity submission;
  const SubmissionCard({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: submission.studentImageUrl != null
              ? NetworkImage(submission.studentImageUrl!)
              : null,
          child: submission.studentImageUrl == null
              ? Text(submission.studentName.substring(0, 1))
              : null,
        ),
        title: Text(
          '${submission.studentName} - ${submission.lessonTitle}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Cours : ${submission.courseTitle}\nRendu le ${DateFormat('dd/MM/yyyy HH:mm').format(submission.submissionDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusChip(submission.status),
            if (submission.grade != null)
              Text(
                'Note: ${submission.grade}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        onTap: () {
          // TODO: Naviguer vers la page de correction du rendu
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("La page de correction sera implémentée ici."),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'graded':
        color = Colors.green;
        label = 'Noté';
        break;
      case 'returned':
        color = Colors.blue;
        label = 'Corrigé';
        break;
      case 'submitted':
      default:
        color = Colors.orange;
        label = 'À corriger';
        break;
    }
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
