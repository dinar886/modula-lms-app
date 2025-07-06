// lib/features/4_instructor_space/quiz_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';

import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

class QuizEditorPage extends StatelessWidget {
  final int lessonId;
  const QuizEditorPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<QuizEditorBloc>()..add(FetchQuizForEditing(lessonId)),
      child: BlocConsumer<QuizEditorBloc, QuizEditorState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == QuizEditorStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          } else if (state.status == QuizEditorStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quiz sauvegardé avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.status == QuizEditorStatus.initial
                    ? 'Chargement...'
                    : 'Éditer le Quiz',
              ),
              actions: [
                if (state.isDirty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilledButton(
                      onPressed: state.status == QuizEditorStatus.saving
                          ? null
                          : () => context.read<QuizEditorBloc>().add(
                              SaveQuizPressed(),
                            ),
                      child: state.status == QuizEditorStatus.saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuizEditorState state) {
    if (state.status == QuizEditorStatus.loading ||
        state.status == QuizEditorStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextFormField(
          initialValue: state.quiz.title,
          decoration: const InputDecoration(
            labelText: 'Titre du Quiz',
            border: OutlineInputBorder(),
          ),
          onChanged: (newTitle) {
            final updatedQuiz = state.quiz.copyWith(title: newTitle);
            context.read<QuizEditorBloc>().add(QuizChanged(updatedQuiz));
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: state.quiz.description,
          decoration: const InputDecoration(
            labelText: 'Description du Quiz',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (newDescription) {
            final updatedQuiz = state.quiz.copyWith(
              description: newDescription,
            );
            context.read<QuizEditorBloc>().add(QuizChanged(updatedQuiz));
          },
        ),
        const Divider(height: 32),
        ...state.quiz.questions.map((question) {
          final questionIndex = state.quiz.questions.indexOf(question);
          return _QuestionEditorCard(
            key: ValueKey(question.id),
            question: question,
            questionIndex: questionIndex,
          );
        }),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une question'),
          onPressed: () {
            final newQuestion = QuestionEntity(
              id: DateTime.now().millisecondsSinceEpoch,
              text: 'Nouvelle Question',
              answers: [],
            );
            final newQuestions = [...state.quiz.questions, newQuestion];
            final updatedQuiz = state.quiz.copyWith(questions: newQuestions);
            context.read<QuizEditorBloc>().add(QuizChanged(updatedQuiz));
          },
        ),
      ],
    );
  }
}

class _QuestionEditorCard extends StatelessWidget {
  final QuestionEntity question;
  final int questionIndex;

  const _QuestionEditorCard({
    super.key,
    required this.question,
    required this.questionIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();
    final state = bloc.state;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: question.text,
              decoration: InputDecoration(
                labelText: 'Question ${questionIndex + 1}',
              ),
              onChanged: (newText) {
                final updatedQuestion = question.copyWith(text: newText);
                final newQuestions = List<QuestionEntity>.from(
                  state.quiz.questions,
                );
                newQuestions[questionIndex] = updatedQuestion;
                bloc.add(
                  QuizChanged(state.quiz.copyWith(questions: newQuestions)),
                );
              },
            ),
            const SizedBox(height: 16),
            ...question.answers.map((answer) {
              final answerIndex = question.answers.indexOf(answer);
              return _AnswerEditorRow(
                answer: answer,
                answerIndex: answerIndex,
                questionIndex: questionIndex,
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Ajouter une réponse'),
                  onPressed: () {
                    final newAnswer = AnswerEntity(
                      id: DateTime.now().millisecondsSinceEpoch,
                      text: '',
                      isCorrect: false,
                    );
                    final updatedAnswers = [...question.answers, newAnswer];
                    final updatedQuestion = question.copyWith(
                      answers: updatedAnswers,
                    );
                    final newQuestions = List<QuestionEntity>.from(
                      state.quiz.questions,
                    );
                    newQuestions[questionIndex] = updatedQuestion;
                    bloc.add(
                      QuizChanged(state.quiz.copyWith(questions: newQuestions)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    final newQuestions = List<QuestionEntity>.from(
                      state.quiz.questions,
                    )..removeAt(questionIndex);
                    bloc.add(
                      QuizChanged(state.quiz.copyWith(questions: newQuestions)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerEditorRow extends StatelessWidget {
  final AnswerEntity answer;
  final int questionIndex;
  final int answerIndex;

  const _AnswerEditorRow({
    required this.answer,
    required this.questionIndex,
    required this.answerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();
    final state = bloc.state;
    final question = state.quiz.questions[questionIndex];

    return Row(
      children: [
        Radio<bool>(
          value: true,
          groupValue: answer.isCorrect,
          onChanged: (value) {
            final resetAnswers = question.answers
                .map((a) => a.copyWith(isCorrect: false))
                .toList();
            final updatedAnswer = resetAnswers[answerIndex].copyWith(
              isCorrect: true,
            );
            resetAnswers[answerIndex] = updatedAnswer;
            final updatedQuestion = question.copyWith(answers: resetAnswers);
            final newQuestions = List<QuestionEntity>.from(
              state.quiz.questions,
            );
            newQuestions[questionIndex] = updatedQuestion;
            bloc.add(QuizChanged(state.quiz.copyWith(questions: newQuestions)));
          },
        ),
        Expanded(
          child: TextFormField(
            initialValue: answer.text,
            decoration: const InputDecoration(hintText: 'Texte de la réponse'),
            onChanged: (newText) {
              final updatedAnswer = answer.copyWith(text: newText);
              final newAnswers = List<AnswerEntity>.from(question.answers);
              newAnswers[answerIndex] = updatedAnswer;
              final updatedQuestion = question.copyWith(answers: newAnswers);
              final newQuestions = List<QuestionEntity>.from(
                state.quiz.questions,
              );
              newQuestions[questionIndex] = updatedQuestion;
              bloc.add(
                QuizChanged(state.quiz.copyWith(questions: newQuestions)),
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: () {
            final newAnswers = List<AnswerEntity>.from(question.answers)
              ..removeAt(answerIndex);
            final updatedQuestion = question.copyWith(answers: newAnswers);
            final newQuestions = List<QuestionEntity>.from(
              state.quiz.questions,
            );
            newQuestions[questionIndex] = updatedQuestion;
            bloc.add(QuizChanged(state.quiz.copyWith(questions: newQuestions)));
          },
        ),
      ],
    );
  }
}
