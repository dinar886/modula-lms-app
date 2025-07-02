import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/quiz_editor_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/quiz_editor_event.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/quiz_editor_state.dart';

class QuizEditorPage extends StatelessWidget {
  final int lessonId;
  const QuizEditorPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<QuizEditorBloc>()..add(FetchQuizForEditing(lessonId)),
      child: BlocListener<QuizEditorBloc, QuizEditorState>(
        // Ce listener va simplement rafraîchir les données après chaque action.
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          // On pourrait ajouter des messages de succès/erreur ici.
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Éditeur de Quiz')),
          body: BlocBuilder<QuizEditorBloc, QuizEditorState>(
            builder: (context, state) {
              if (state.status == QuizEditorStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == QuizEditorStatus.success) {
                return ListView.builder(
                  itemCount:
                      state.quiz.questions.length +
                      1, // +1 pour le bouton "Ajouter"
                  itemBuilder: (context, index) {
                    if (index == state.quiz.questions.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une question'),
                          onPressed: () =>
                              _showAddQuestionDialog(context, state.quiz.id),
                        ),
                      );
                    }
                    final question = state.quiz.questions[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                question.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  context.read<QuizEditorBloc>().add(
                                    DeleteQuestion(question.id),
                                  );
                                  context.read<QuizEditorBloc>().add(
                                    FetchQuizForEditing(lessonId),
                                  );
                                },
                              ),
                            ),
                            const Divider(),
                            ...question.answers.map(
                              (answer) => ListTile(
                                leading: Radio<bool>(
                                  value: answer.isCorrect,
                                  groupValue: true,
                                  onChanged: (value) {
                                    context.read<QuizEditorBloc>().add(
                                      SetCorrectAnswer(
                                        questionId: question.id,
                                        answerId: answer.id,
                                      ),
                                    );
                                    context.read<QuizEditorBloc>().add(
                                      FetchQuizForEditing(lessonId),
                                    );
                                  },
                                ),
                                title: Text(answer.text),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    context.read<QuizEditorBloc>().add(
                                      DeleteAnswer(answer.id),
                                    );
                                    context.read<QuizEditorBloc>().add(
                                      FetchQuizForEditing(lessonId),
                                    );
                                  },
                                ),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ajouter une réponse'),
                              onPressed: () =>
                                  _showAddAnswerDialog(context, question.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(
                child: Text('Erreur lors du chargement du quiz.'),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddQuestionDialog(BuildContext context, int quizId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle Question'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Texte de la question'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<QuizEditorBloc>().add(
                  AddQuestion(quizId: quizId, questionText: controller.text),
                );
                context.read<QuizEditorBloc>().add(
                  FetchQuizForEditing(lessonId),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showAddAnswerDialog(BuildContext context, int questionId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle Réponse'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Texte de la réponse'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<QuizEditorBloc>().add(
                  AddAnswer(
                    questionId: questionId,
                    answerText: controller.text,
                  ),
                );
                context.read<QuizEditorBloc>().add(
                  FetchQuizForEditing(lessonId),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
