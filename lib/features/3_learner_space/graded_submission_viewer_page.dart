// lib/features/3_learner_space/graded_submission_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/4_instructor_space/grading_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:modula_lms/features/course_player/lesson_viewer_page.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Page de visualisation de la correction pour l'étudiant.
///
/// Affiche la note, le feedback de l'instructeur et le rendu original de l'étudiant.
/// La note et le cercle de progression ne s'affichent que pour les leçons de type "évaluation".
class GradedSubmissionViewerPage extends StatelessWidget {
  final int submissionId;
  const GradedSubmissionViewerPage({super.key, required this.submissionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<GradingBloc>()..add(FetchSubmissionDetails(submissionId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
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
              return _buildProfessionalLayout(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// Construit la mise en page principale avec un CustomScrollView.
  Widget _buildProfessionalLayout(BuildContext context, GradingState state) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          delegate: _GradingHeaderDelegate(
            state: state,
            minExtent: 140,
            maxExtent: 280,
          ),
          pinned: true,
        ),
        _buildDetailedFeedbackList(context, state),
        SliverToBoxAdapter(child: _buildOriginalLessonSection(context, state)),
      ],
    );
  }

  /// Construit la liste des blocs de correction.
  Widget _buildDetailedFeedbackList(BuildContext context, GradingState state) {
    final studentContent = state.submission.studentContent;
    final feedback = state.feedback;

    if (studentContent.isEmpty && feedback.files.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              "Aucun travail n'a été soumis et aucun fichier de correction n'a été ajouté.",
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < feedback.files.length) {
          final fileBlock = feedback.files[index];
          return _buildTeacherFileCard(context, fileBlock);
        }

        final contentIndex = index - feedback.files.length;
        final block = studentContent[contentIndex];
        final comment = feedback.comments[block.localId] ?? '';

        return Column(
          children: [
            _buildStudentContentCard(context, block),
            if (comment.isNotEmpty) _buildTeacherFeedbackCard(context, comment),
            if (contentIndex < studentContent.length - 1)
              const SizedBox(height: 8),
          ],
        );
      }, childCount: studentContent.length + feedback.files.length),
    );
  }

  /// Construit la carte pour le contenu soumis par l'étudiant.
  Widget _buildStudentContentCard(
    BuildContext context,
    ContentBlockEntity block,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  "Votre rendu",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildBlockWidget(context, block),
          ),
        ],
      ),
    );
  }

  /// Construit la carte pour le feedback de l'instructeur.
  Widget _buildTeacherFeedbackCard(BuildContext context, String comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.school_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                comment,
                style: TextStyle(color: Colors.blue.shade900, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la carte pour un fichier de correction de l'instructeur.
  Widget _buildTeacherFileCard(
    BuildContext context,
    ContentBlockEntity fileBlock,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Fichier de correction",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            _buildFileTile(
              context,
              fileBlock,
              icon: Icons.download_for_offline_outlined,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section pour l'énoncé original (extensible).
  Widget _buildOriginalLessonSection(BuildContext context, GradingState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: const Text(
            "Revoir l'énoncé original",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: const Icon(Icons.article_outlined),
          backgroundColor: Colors.white,
          children: state.submission.lessonStatement.map((block) {
            if (block.blockType == ContentBlockType.quiz) {
              final quizId = int.tryParse(block.content) ?? 0;
              if (quizId > 0) {
                return _GradedQuizView(
                  quizId: quizId,
                  studentId: state.submission.studentId.toString(),
                );
              }
            }
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildBlockWidget(context, block),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Widget générique pour afficher n'importe quel type de bloc (texte, image, fichier, etc.).
  Widget _buildBlockWidget(BuildContext context, ContentBlockEntity block) {
    switch (block.blockType) {
      case ContentBlockType.text:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextContentWidget(
            markdownContent: block.content,
            metadata: block.metadata,
          ),
        );
      case ContentBlockType.image:
        return ImageWidget(imageUrl: block.content, metadata: block.metadata);
      case ContentBlockType.video:
        final videoId = YoutubePlayer.convertUrlToId(block.content);
        if (videoId != null && videoId.isNotEmpty) {
          return YouTubeBlockWidget(videoId: videoId);
        } else {
          return VideoPlayerWidget(videoUrl: block.content);
        }
      case ContentBlockType.document:
        return _buildFileTile(
          context,
          block,
          icon: Icons.insert_drive_file_outlined,
        );
      case ContentBlockType.submission_placeholder:
      case ContentBlockType
          .quiz: // Le quiz est géré dans _buildOriginalLessonSection, on ne l'affiche pas ici.
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Affiche une tuile cliquable pour un fichier (PDF, etc.).
  Widget _buildFileTile(
    BuildContext context,
    ContentBlockEntity fileBlock, {
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(fileBlock.metadata['fileName'] ?? 'Fichier'),
      trailing: const Icon(Icons.visibility_outlined),
      onTap: () => context.push(
        '/pdf-viewer',
        extra: {
          'url': fileBlock.content,
          'title': fileBlock.metadata['fileName'] ?? 'Document',
        },
      ),
    );
  }
}

/// Widget dédié à l'affichage du quiz corrigé.
class _GradedQuizView extends StatelessWidget {
  final int quizId;
  final String studentId;

  const _GradedQuizView({required this.quizId, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuizBloc>()
        ..add(FetchQuiz(quizId: quizId, studentId: studentId, maxAttempts: 0)),
      child: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          if (state.status == QuizStatus.loading ||
              state.status == QuizStatus.initial) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.status == QuizStatus.failure) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text(state.error)),
            );
          }
          if (state.status == QuizStatus.showingResult &&
              state.lastAttempt != null) {
            return _buildQuizResult(context, state);
          }
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text("Les résultats du quiz ne sont pas disponibles."),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizResult(BuildContext context, QuizState state) {
    final attempt = state.lastAttempt!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Chip(
              label: Text(
                'Score au quiz : ${attempt.score.toStringAsFixed(1)} / 20.0',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: attempt.score >= 10 ? Colors.green : Colors.red,
            ),
          ),
          const Divider(height: 32),
          ...state.quiz.questions.map((question) {
            final userAnswer = attempt.answers[question.id];

            if (question.questionType == QuestionType.fill_in_the_blank) {
              final isCorrect =
                  (userAnswer as String? ?? '').trim().toLowerCase() ==
                  (question.correctTextAnswer ?? '').trim().toLowerCase();
              return _FillInTheBlankResult(
                question: question,
                userAnswer: userAnswer as String? ?? '',
                isCorrect: isCorrect,
              );
            }

            final isCorrect =
                userAnswer ==
                question.answers
                    .firstWhere(
                      (a) => a.isCorrect,
                      orElse: () => const AnswerEntity(
                        id: -1,
                        text: '',
                        isCorrect: false,
                      ),
                    )
                    .id;
            return _McqResult(
              question: question,
              selectedAnswerId: userAnswer as int?,
              isCorrect: isCorrect,
            );
          }),
        ],
      ),
    );
  }
}

class _McqResult extends StatelessWidget {
  final QuestionEntity question;
  final int? selectedAnswerId;
  final bool isCorrect;
  const _McqResult({
    required this.question,
    this.selectedAnswerId,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.text, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...question.answers.map((answer) {
              final bool isSelected = answer.id == selectedAnswerId;
              final bool isCorrectAnswer = answer.isCorrect;
              Color? tileColor;
              Icon? trailingIcon;
              if (isCorrectAnswer) {
                tileColor = Colors.green.withOpacity(0.15);
                trailingIcon = const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                );
              }
              if (isSelected && !isCorrectAnswer) {
                tileColor = Colors.red.withOpacity(0.15);
                trailingIcon = const Icon(Icons.cancel, color: Colors.red);
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(answer.text),
                  trailing: trailingIcon,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FillInTheBlankResult extends StatelessWidget {
  final QuestionEntity question;
  final String userAnswer;
  final bool isCorrect;
  const _FillInTheBlankResult({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text.replaceAll('{{blank}}', '...'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              "Votre réponse :",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              userAnswer.isNotEmpty ? '"$userAnswer"' : "(aucune réponse)",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              const Text(
                "Bonne réponse :",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '"${question.correctTextAnswer}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Délégué pour l'en-tête persistant et dynamique.
///
/// **Mise à jour de la logique d'affichage :**
/// - Le cercle de note est maintenant encapsulé dans un widget conditionnel.
/// - Il ne s'affiche que si `submission.lessonType` est `LessonType.evaluation`.
/// - Si c'est un `LessonType.devoir`, le cercle est remplacé par un `SizedBox.shrink()` (un widget vide).
/// - Le padding du commentaire général est ajusté dynamiquement pour occuper l'espace correctement.
class _GradingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final GradingState state;
  @override
  final double minExtent;
  @override
  final double maxExtent;

  _GradingHeaderDelegate({
    required this.state,
    required this.minExtent,
    required this.maxExtent,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final submission = state.submission;
    final progress = shrinkOffset / maxExtent;

    // Widget pour afficher la note (cercle + texte)
    Widget gradeDisplayWidget;

    // La section de la note n'est affichée que pour les évaluations
    if (submission.lessonType == LessonType.evaluation) {
      String gradeText = submission.grade != null
          ? submission.grade!.toStringAsFixed(1)
          : 'N/A';

      gradeDisplayWidget = SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: (submission.grade ?? 0) / 20.0,
              strokeWidth: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                submission.grade == null
                    ? Colors.grey.withOpacity(0.5)
                    : submission.grade! >= 10
                    ? Colors.greenAccent
                    : Colors.amber,
              ),
            ),
            Center(
              child: Text(
                gradeText,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Pour les devoirs, on n'affiche rien (pas de cercle, pas de note)
      gradeDisplayWidget = const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor,
        boxShadow: [
          if (shrinkOffset > 0)
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: 20,
            left: 16 + 80 * progress,
            child: Opacity(
              opacity: math.max(0.0, 1.0 - progress * 2),
              child: Text(
                submission.lessonTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Opacity(
              opacity: math.max(0.0, progress * 2 - 1.0),
              child: AppBar(
                title: Text(submission.lessonTitle),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Opacity(
              opacity: math.max(0.0, 1.0 - progress * 1.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      gradeDisplayWidget, // Le widget conditionnel est inséré ici
                      Expanded(
                        child: Padding(
                          // Le padding est ajusté pour que le texte ne soit pas décalé si la note n'est pas là
                          padding: EdgeInsets.only(
                            left: submission.lessonType == LessonType.evaluation
                                ? 16.0
                                : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Commentaire Général",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.feedback.generalComment.isNotEmpty
                                    ? state.feedback.generalComment
                                    : "Aucun commentaire général.",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
          Positioned(top: 40, left: 0, child: BackButton(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
