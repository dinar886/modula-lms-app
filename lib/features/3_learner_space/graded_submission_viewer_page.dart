// lib/features/3_learner_space/graded_submission_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/4_instructor_space/grading_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:modula_lms/features/course_player/lesson_viewer_page.dart'; // Pour réutiliser les widgets de bloc

class GradedSubmissionViewerPage extends StatelessWidget {
  final int submissionId;
  const GradedSubmissionViewerPage({super.key, required this.submissionId});

  @override
  Widget build(BuildContext context) {
    // On réutilise le GradingBloc car il contient la logique pour fetch les détails
    return BlocProvider(
      create: (context) =>
          sl<GradingBloc>()..add(FetchSubmissionDetails(submissionId)),
      child: Scaffold(
        appBar: AppBar(title: const Text("Correction de votre travail")),
        body: BlocBuilder<GradingBloc, GradingState>(
          builder: (context, state) {
            if (state.status == GradingStatus.loading ||
                state.status == GradingStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == GradingStatus.failure) {
              return Center(child: Text("Erreur: ${state.error}"));
            }
            if (state.status == GradingStatus.loaded) {
              return _buildCorrectionView(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCorrectionView(BuildContext context, GradingState state) {
    final submission = state.submission;
    final feedback = state.feedback;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Carte Résumé
        Card(
          color: Theme.of(context).colorScheme.surface,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  submission.lessonTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (submission.grade != null) ...[
                  Text(
                    'Votre Note',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${submission.grade!.toStringAsFixed(1)} / 20.0',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: submission.grade! >= 10
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (feedback.generalComment.isNotEmpty) ...[
                  const Text(
                    'Commentaire de l\'instructeur :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feedback.generalComment,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),

        const Divider(height: 32),

        // Détails de la correction
        const Text(
          "Détail de la correction",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...submission.studentContent.map((block) {
          final comment = feedback.comments[block.localId];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AbsorbPointer(child: _buildBlockWidget(context, block)),
                  if (comment != null && comment.isNotEmpty) ...[
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.comment,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text("Feedback de l'instructeur"),
                      subtitle: Text(comment),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        // Fichiers de correction
        if (feedback.files.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "Fichiers joints par l'instructeur",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...feedback.files.map((fileBlock) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.download_for_offline_outlined),
                title: Text(fileBlock.metadata['fileName'] ?? 'Fichier'),
                onTap: () => context.push(
                  '/pdf-viewer',
                  extra: {
                    'url': fileBlock.content,
                    'title': fileBlock.metadata['fileName'] ?? 'Document',
                  },
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildBlockWidget(BuildContext context, ContentBlockEntity block) {
    switch (block.blockType) {
      case ContentBlockType.text:
        return TextContentWidget(
          markdownContent: block.content,
          metadata: block.metadata,
        );
      case ContentBlockType.image:
        return ImageWidget(imageUrl: block.content, metadata: block.metadata);
      case ContentBlockType.document:
        return ListTile(
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(block.metadata['fileName'] ?? 'Fichier attaché'),
          onTap: () => context.push(
            '/pdf-viewer',
            extra: {
              'url': block.content,
              'title': block.metadata['fileName'] ?? 'Document',
            },
          ),
        );
      default:
        return Text("Type de bloc non supporté: ${block.blockType}");
    }
  }
}
