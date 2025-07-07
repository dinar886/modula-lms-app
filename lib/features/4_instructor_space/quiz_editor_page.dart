// lib/features/4_instructor_space/quiz_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

// CORRECTION 1 : Le widget est maintenant un StatefulWidget.
class QuizEditorPage extends StatefulWidget {
  final int quizId;
  const QuizEditorPage({super.key, required this.quizId});

  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  // Map pour stocker les contrôleurs de texte, ce qui évite la perte de focus.
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    // On libère la mémoire de tous les contrôleurs.
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Prépare ou met à jour les contrôleurs de texte pour le quiz.
  void _prepareControllers(QuizEntity quiz) {
    // Clé pour le titre
    final titleKey = 'quiz_${quiz.id}_title';
    _controllers.putIfAbsent(
      titleKey,
      () => TextEditingController(text: quiz.title),
    );

    // Clé pour la description
    final descKey = 'quiz_${quiz.id}_desc';
    _controllers.putIfAbsent(
      descKey,
      () => TextEditingController(text: quiz.description),
    );

    // Clés pour chaque question et réponse
    for (var q in quiz.questions) {
      final qKey = 'q_${q.id}';
      _controllers.putIfAbsent(qKey, () => TextEditingController(text: q.text));
      for (var a in q.answers) {
        final aKey = 'a_${a.id}';
        _controllers.putIfAbsent(
          aKey,
          () => TextEditingController(text: a.text),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<QuizEditorBloc>()..add(FetchQuizForEditing(widget.quizId)),
      child: BlocConsumer<QuizEditorBloc, QuizEditorState>(
        listenWhen: (prev, current) =>
            prev.status != current.status || prev.quiz != current.quiz,
        listener: (context, state) {
          if (state.status == QuizEditorStatus.loaded) {
            // Quand le quiz est chargé ou modifié, on s'assure que les contrôleurs sont prêts.
            _prepareControllers(state.quiz);
          } else if (state.status == QuizEditorStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quiz sauvegardé avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
            // On renvoie l'ID du quiz sauvegardé à la page précédente.
            context.pop(state.quiz.id);
          } else if (state.status == QuizEditorStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return PopScope(
            onPopInvoked: (didPop) {
              if (didPop && state.quiz.id == 0) {
                context.pop(widget.quizId);
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.quizId == 0 ? 'Nouveau Quiz' : 'Éditer le Quiz',
                ),
                actions: [
                  if (state.status == QuizEditorStatus.saving)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.save_outlined),
                      tooltip: 'Sauvegarder',
                      onPressed: () =>
                          context.read<QuizEditorBloc>().add(SaveQuiz()),
                    ),
                ],
              ),
              body: _buildBody(context, state),
            ),
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

    final bloc = context.read<QuizEditorBloc>();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Champ pour le titre du quiz.
        TextFormField(
          controller: _controllers['quiz_${state.quiz.id}_title'],
          decoration: const InputDecoration(
            labelText: 'Titre du Quiz',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) =>
              bloc.add(UpdateQuiz(state.quiz.copyWith(title: value))),
        ),
        const SizedBox(height: 16),
        // Champ pour la description.
        TextFormField(
          controller: _controllers['quiz_${state.quiz.id}_desc'],
          decoration: const InputDecoration(
            labelText: 'Description (optionnel)',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
          onChanged: (value) =>
              bloc.add(UpdateQuiz(state.quiz.copyWith(description: value))),
        ),
        const Divider(height: 32),
        // Affichage des questions
        ...state.quiz.questions.map((question) {
          return _QuestionEditorCard(
            key: ValueKey(question.id), // Clé unique pour la reconstruction
            question: question,
            controller: _controllers['q_${question.id}']!,
          );
        }),
        const SizedBox(height: 20),
        // Bouton pour ajouter une question
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une question'),
          onPressed: () => bloc.add(AddQuestion()),
        ),
      ],
    );
  }
}

// CORRECTION 2 : Les widgets internes deviennent aussi des StatefulWidget pour gérer leur propre contrôleur.
class _QuestionEditorCard extends StatefulWidget {
  final QuestionEntity question;
  final TextEditingController controller;

  const _QuestionEditorCard({
    super.key,
    required this.question,
    required this.controller,
  });

  @override
  State<_QuestionEditorCard> createState() => _QuestionEditorCardState();
}

class _QuestionEditorCardState extends State<_QuestionEditorCard> {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();
    final questionIndex = bloc.state.quiz.questions.indexOf(widget.question);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Champ pour le texte de la question
            TextFormField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: 'Texte de la question',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => bloc.add(DeleteQuestion(widget.question.id)),
                ),
              ),
              onChanged: (value) => bloc.add(
                UpdateQuestion(widget.question.copyWith(text: value)),
              ),
            ),
            const SizedBox(height: 16),
            // Affichage des réponses
            ...widget.question.answers.map((answer) {
              // On récupère le contrôleur de la réponse depuis le widget parent.
              final answerController = (context
                  .findAncestorStateOfType<_QuizEditorPageState>()!
                  ._controllers['a_${answer.id}'])!;
              return _AnswerEditorRow(
                key: ValueKey(answer.id),
                question: widget.question,
                answer: answer,
                controller: answerController,
              );
            }),
            const SizedBox(height: 8),
            // Bouton pour ajouter une réponse
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => bloc.add(AddAnswer(widget.question.id)),
                child: const Text("+ Ajouter une réponse"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerEditorRow extends StatelessWidget {
  final QuestionEntity question;
  final AnswerEntity answer;
  final TextEditingController controller;

  const _AnswerEditorRow({
    super.key,
    required this.question,
    required this.answer,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();
    final isCorrect = answer.isCorrect;

    return Row(
      children: [
        // Bouton radio pour marquer la bonne réponse
        Radio<bool>(
          value: true,
          groupValue: isCorrect,
          onChanged: (value) {
            if (value == true) {
              bloc.add(
                SetCorrectAnswer(questionId: question.id, answerId: answer.id),
              );
            }
          },
        ),
        // Champ pour le texte de la réponse
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Texte de la réponse'),
            onChanged: (value) =>
                bloc.add(UpdateAnswer(answer.copyWith(text: value))),
          ),
        ),
        // Bouton pour supprimer la réponse
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => bloc.add(DeleteAnswer(answer.id)),
        ),
      ],
    );
  }
}
