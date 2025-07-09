// lib/features/4_instructor_space/quiz_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

class QuizEditorPage extends StatefulWidget {
  final int quizId;
  const QuizEditorPage({super.key, required this.quizId});

  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prepareControllers(QuizEntity quiz) {
    final titleKey = 'quiz_${quiz.id}_title';
    _controllers.putIfAbsent(
      titleKey,
      () => TextEditingController(text: quiz.title),
    );

    final descKey = 'quiz_${quiz.id}_desc';
    _controllers.putIfAbsent(
      descKey,
      () => TextEditingController(text: quiz.description),
    );

    for (var q in quiz.questions) {
      final qKey = 'q_${q.id}';
      _controllers.putIfAbsent(qKey, () => TextEditingController(text: q.text));

      if (q.questionType == QuestionType.fill_in_the_blank) {
        final fitbKey = 'fitb_a_${q.id}';
        _controllers.putIfAbsent(
          fitbKey,
          () => TextEditingController(text: q.correctTextAnswer),
        );
      } else {
        for (var a in q.answers) {
          final aKey = 'a_${a.id}';
          _controllers.putIfAbsent(
            aKey,
            () => TextEditingController(text: a.text),
          );
        }
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
            _prepareControllers(state.quiz);
          } else if (state.status == QuizEditorStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quiz sauvegardé avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
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
              floatingActionButton: _buildAddQuestionFab(context),
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
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 80),
      children: [
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
        ...state.quiz.questions.map((question) {
          // On passe le bon contrôleur en fonction du type de question.
          final questionController = _controllers['q_${question.id}']!;
          if (question.questionType == QuestionType.mcq) {
            return _McqQuestionEditorCard(
              key: ValueKey(question.id),
              question: question,
              controller: questionController,
            );
          } else {
            return _FillInTheBlankQuestionEditorCard(
              key: ValueKey(question.id),
              question: question,
              questionController: questionController,
              answerController: _controllers['fitb_a_${question.id}']!,
            );
          }
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  // FAB (Floating Action Button) pour ajouter une question.
  Widget _buildAddQuestionFab(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();
    return PopupMenuButton<QuestionType>(
      onSelected: (type) => bloc.add(AddQuestion(type)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: QuestionType.mcq,
          child: ListTile(
            leading: Icon(Icons.radio_button_checked),
            title: Text('Question à choix multiple'),
          ),
        ),
        const PopupMenuItem(
          value: QuestionType.fill_in_the_blank,
          child: ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('Texte à trous'),
          ),
        ),
      ],
      // Personnalisation du FAB
      child: const FloatingActionButton.extended(
        onPressed: null, // Le onPressed est géré par le PopupMenuButton
        label: Text('Ajouter une question'),
        icon: Icon(Icons.add),
      ),
    );
  }
}

// --- EDITEUR POUR QUESTION QCM ---
class _McqQuestionEditorCard extends StatelessWidget {
  final QuestionEntity question;
  final TextEditingController controller;

  const _McqQuestionEditorCard({
    super.key,
    required this.question,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Texte de la question',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => bloc.add(DeleteQuestion(question.id)),
                ),
              ),
              onChanged: (value) =>
                  bloc.add(UpdateQuestion(question.copyWith(text: value))),
            ),
            const SizedBox(height: 16),
            ...question.answers.map((answer) {
              final answerController = (context
                  .findAncestorStateOfType<_QuizEditorPageState>()!
                  ._controllers['a_${answer.id}'])!;
              return _AnswerEditorRow(
                key: ValueKey(answer.id),
                question: question,
                answer: answer,
                controller: answerController,
              );
            }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => bloc.add(AddAnswer(question.id)),
                child: const Text("+ Ajouter une réponse"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- EDITEUR POUR QUESTION TEXTE À TROUS ---
class _FillInTheBlankQuestionEditorCard extends StatelessWidget {
  final QuestionEntity question;
  final TextEditingController questionController;
  final TextEditingController answerController;

  const _FillInTheBlankQuestionEditorCard({
    super.key,
    required this.question,
    required this.questionController,
    required this.answerController,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: 'Phrase à compléter',
                hintText: 'Utilisez {{blank}} pour le mot manquant.',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => bloc.add(DeleteQuestion(question.id)),
                ),
              ),
              onChanged: (value) =>
                  bloc.add(UpdateQuestion(question.copyWith(text: value))),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: answerController,
              decoration: const InputDecoration(
                labelText: 'Mot correct',
                hintText: 'Le mot qui remplace {{blank}}',
              ),
              onChanged: (value) => bloc.add(
                UpdateQuestion(question.copyWith(correctTextAnswer: value)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET POUR UNE LIGNE DE RÉPONSE (QCM) ---
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
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Texte de la réponse'),
            onChanged: (value) =>
                bloc.add(UpdateAnswer(answer.copyWith(text: value))),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => bloc.add(DeleteAnswer(answer.id)),
        ),
      ],
    );
  }
}
