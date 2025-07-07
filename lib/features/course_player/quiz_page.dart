// lib/features/course_player/quiz_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizPage extends StatelessWidget {
  final int lessonId;
  const QuizPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthenticationBloc>().state.user.id;
    return BlocProvider(
      create: (context) =>
          sl<QuizBloc>()..add(FetchQuiz(lessonId: lessonId, studentId: userId)),
      child: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.quiz.title.isNotEmpty
                    ? state.quiz.title
                    : 'Chargement du Quiz...',
              ),
            ),
            body: _buildBody(context, state),
            bottomNavigationBar:
                (state.status == QuizStatus.loaded && state.canAttemptQuiz)
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FilledButton(
                      onPressed: () {
                        final studentId = context
                            .read<AuthenticationBloc>()
                            .state
                            .user
                            .id;
                        context.read<QuizBloc>().add(
                          SubmitQuiz(studentId: studentId, lessonId: lessonId),
                        );
                      },
                      child: const Text('Soumettre le Quiz'),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuizState state) {
    switch (state.status) {
      case QuizStatus.loading:
      case QuizStatus.initial:
        return const Center(child: CircularProgressIndicator());

      case QuizStatus.loaded:
        if (!state.canAttemptQuiz) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Vous avez déjà effectué le nombre maximum de tentatives pour ce quiz.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: state.quiz.questions.length,
          itemBuilder: (context, index) {
            final question = state.quiz.questions[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: question.answers.map((answer) {
                        return RadioListTile<int>(
                          title: Text(answer.text),
                          value: answer.id,
                          groupValue: state.userAnswers[question.id],
                          onChanged: (value) {
                            if (value != null) {
                              context.read<QuizBloc>().add(
                                AnswerSelected(
                                  questionId: question.id,
                                  answerId: value,
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case QuizStatus.submitted:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quiz Terminé !',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text(
                'Votre score :',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${state.score?.toStringAsFixed(0)} %',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case QuizStatus.failure:
        return Center(
          child: Text(state.error, style: const TextStyle(color: Colors.red)),
        );
    }
  }
}
