// lib/features/4_instructor_space/grading_page.dart
import 'package:file_picker/file_picker.dart'; // Import pour le sélecteur de fichiers
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // On le garde pour le type XFile
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/4_instructor_space/grading_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:modula_lms/features/course_player/lesson_viewer_page.dart';

// Le reste de la classe est identique, seule la section de correction est modifiée

class GradingPage extends StatelessWidget {
  final int submissionId;
  const GradingPage({super.key, required this.submissionId});

  @override
  Widget build(BuildContext context) {
    // On utilise MultiBlocProvider pour gérer à la fois la correction et le quiz
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<GradingBloc>()..add(FetchSubmissionDetails(submissionId)),
        ),
        BlocProvider(create: (context) => sl<QuizBloc>()),
      ],
      child: BlocConsumer<GradingBloc, GradingState>(
        listenWhen: (prev, current) => prev.status != current.status,
        listener: (context, state) {
          if (state.status == GradingStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Correction envoyée !'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(); // Retourne à la liste des rendus
          }
          if (state.status == GradingStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Si on trouve un quiz associé, on le charge
          if (state.status == GradingStatus.loaded &&
              state.submission.associatedQuizId != null) {
            final studentId = state.submission.studentId.toString();
            context.read<QuizBloc>().add(
              FetchQuiz(
                quizId: state.submission.associatedQuizId!,
                studentId: studentId,
                maxAttempts: -1, // on veut juste voir le dernier résultat
              ),
            );
          }
        },
        builder: (context, state) {
          // Ajout du GestureDetector pour fermer le clavier
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  state.submission.lessonTitle.isNotEmpty
                      ? "Correction de : ${state.submission.lessonTitle}"
                      : 'Chargement...',
                ),
              ),
              body: _buildBody(context, state),
              bottomNavigationBar: _buildBottomBar(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, GradingState state) {
    if (state.status == GradingStatus.loading ||
        state.status == GradingStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == GradingStatus.failure) {
      return Center(child: Text("Erreur: ${state.error}"));
    }

    final submission = state.submission;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Affichage du travail de l'élève
        const Text(
          "Travail de l'élève",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        if (submission.studentContent.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "L'élève n'a soumis aucun contenu.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ...submission.studentContent.map(
            (block) => _buildStudentBlock(context, block, state),
          ),

        // Affichage des résultats du Quiz
        if (submission.associatedQuizId != null) _buildQuizResultSection(),

        const SizedBox(height: 24),

        // 2. Section de correction de l'instructeur
        const Text(
          "Correction",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        _buildCorrectionSection(context, state),
      ],
    );
  }

  Widget _buildStudentBlock(
    BuildContext context,
    ContentBlockEntity block,
    GradingState state,
  ) {
    final bloc = context.read<GradingBloc>();
    final isDocument = block.blockType == ContentBlockType.document;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AbsorbPointer(
              absorbing: !isDocument,
              child: _buildBlockWidget(context, block),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: state.feedback.comments[block.localId],
              onChanged: (value) {
                final newComments = Map<String, String>.from(
                  state.feedback.comments,
                );
                newComments[block.localId] = value;
                bloc.add(
                  UpdateFeedback(
                    state.feedback.copyWith(comments: newComments),
                  ),
                );
              },
              decoration: const InputDecoration(
                labelText: 'Commentaire sur ce bloc',
                hintText: 'Ajoutez votre feedback ici...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResultSection() {
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, quizState) {
        if (quizState.status == QuizStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (quizState.status == QuizStatus.failure) {
          return Center(
            child: Text("Erreur de chargement du quiz: ${quizState.error}"),
          );
        }
        if (quizState.status == QuizStatus.showingResult &&
            quizState.lastAttempt != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                "Résultats du Quiz de l'élève",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildQuizResult(context, quizState),
            ],
          );
        }
        return const SizedBox.shrink();
      },
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

  Widget _buildCorrectionSection(BuildContext context, GradingState state) {
    final bloc = context.read<GradingBloc>();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.submission.lessonType == LessonType.evaluation)
              TextFormField(
                initialValue: state.grade?.toString(),
                onChanged: (value) {
                  bloc.add(UpdateGrade(double.tryParse(value)));
                },
                decoration: const InputDecoration(
                  labelText: 'Note sur 20',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.feedback.generalComment,
              onChanged: (value) {
                bloc.add(
                  UpdateFeedback(
                    state.feedback.copyWith(generalComment: value),
                  ),
                );
              },
              decoration: const InputDecoration(
                labelText: 'Commentaire général',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            const Text("Fichiers joints à la correction :"),
            ...state.feedback.files.map((fileBlock) {
              return ListTile(
                leading: fileBlock.uploadStatus == UploadStatus.uploading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.attach_file),
                title: Text(fileBlock.metadata['fileName'] ?? 'Fichier'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      bloc.add(RemoveCorrectionFile(fileBlock.localId)),
                ),
              );
            }),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Ajouter un fichier de correction'),
              onPressed: () async {
                // CORRECTION : Remplacement de ImagePicker par FilePicker
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType
                      .any, // Permet de sélectionner tout type de fichier
                );

                if (result != null && result.files.single.path != null) {
                  final file = XFile(result.files.single.path!);
                  bloc.add(UploadCorrectionFile(file));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, GradingState state) {
    if (state.status != GradingStatus.loaded) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FilledButton.icon(
        icon: const Icon(Icons.send_outlined),
        label: const Text('Confirmer et envoyer la correction'),
        onPressed: state.status == GradingStatus.saving
            ? null
            : () {
                context.read<GradingBloc>().add(SaveCorrection());
              },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildQuizResult(BuildContext context, QuizState state) {
    final attempt = state.lastAttempt;
    if (attempt == null) {
      return const Center(
        child: Text("Erreur: Impossible d'afficher les résultats."),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Quiz : ${state.quiz.title}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Score de l\'élève :',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${attempt.score.toStringAsFixed(1)} / 20.0',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: attempt.score >= 10 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '(${attempt.correctAnswers} / ${attempt.totalQuestions} bonnes réponses)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 32),
            Text(
              'Correction détaillée',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...state.quiz.questions.map((question) {
              final userAnswer = attempt.answers[question.id];
              final correctAnswerId =
                  question.questionType == QuestionType.mcq &&
                      question.answers.any((a) => a.isCorrect)
                  ? question.answers.firstWhere((a) => a.isCorrect).id
                  : null;

              final isCorrect = question.questionType == QuestionType.mcq
                  ? userAnswer == correctAnswerId
                  : (userAnswer as String? ?? '').trim().toLowerCase() ==
                        (question.correctTextAnswer ?? '').trim().toLowerCase();

              if (question.questionType == QuestionType.fill_in_the_blank) {
                return _FillInTheBlankResultCard(
                  question: question,
                  userAnswer: userAnswer as String? ?? '',
                  isCorrect: isCorrect,
                );
              }
              return _McqResultCard(
                question: question,
                selectedAnswerId: userAnswer as int?,
                isCorrect: isCorrect,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _McqResultCard extends StatelessWidget {
  const _McqResultCard({
    required this.question,
    required this.selectedAnswerId,
    required this.isCorrect,
  });

  final QuestionEntity question;
  final int? selectedAnswerId;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...question.answers.map((answer) {
              final isSelected = answer.id == selectedAnswerId;
              final isCorrectAnswer = answer.isCorrect;
              Color color = Colors.transparent;

              if (isSelected && isCorrectAnswer) {
                color = Colors.green.withOpacity(0.1);
              } else if (isSelected && !isCorrectAnswer) {
                color = Colors.red.withOpacity(0.1);
              } else if (isCorrectAnswer) {
                color = Colors.green.withOpacity(0.1);
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: isCorrectAnswer
                        ? Colors.green.shade200
                        : (isSelected
                              ? Colors.red.shade200
                              : Colors.grey.shade300),
                    width: isCorrectAnswer || isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(answer.text)),
                    if (isSelected)
                      const Icon(
                        Icons.radio_button_checked,
                        color: Colors.blueAccent,
                      )
                    else
                      const Icon(Icons.radio_button_off, color: Colors.grey),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FillInTheBlankResultCard extends StatelessWidget {
  const _FillInTheBlankResultCard({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  });

  final QuestionEntity question;
  final String userAnswer;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Réponse de l'élève :",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                userAnswer.isEmpty ? "(Aucune réponse)" : userAnswer,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                "Réponse correcte :",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.correctTextAnswer ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
