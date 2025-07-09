import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';

/// Une page dédiée à l'affichage et à l'interaction avec un quiz.
///
/// Cette page est conçue pour être appelée avec un `lessonId`. Elle charge
/// d'abord les détails de la leçon pour trouver le premier quiz qu'elle contient,
/// puis elle affiche ce quiz.
class QuizPage extends StatelessWidget {
  final int lessonId;
  const QuizPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    // Étape 1: On utilise le LessonDetailBloc pour récupérer les informations
    // de la leçon, qui contiennent les détails du quiz (son ID, etc.).
    return BlocProvider(
      create: (context) =>
          sl<LessonDetailBloc>()
            ..add(FetchLessonDetails(lessonId: lessonId, studentId: studentId)),
      child: Scaffold(
        // L'AppBar est simple et affiche un titre générique pendant le chargement.
        appBar: AppBar(title: const Text('Quiz')),
        body: BlocBuilder<LessonDetailBloc, LessonDetailState>(
          builder: (context, state) {
            // Affiche un indicateur de chargement pendant la récupération des détails.
            if (state is LessonDetailLoading || state is LessonDetailInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            // Affiche un message d'erreur si la récupération échoue.
            if (state is LessonDetailError) {
              return Center(child: Text(state.message));
            }

            // Une fois les détails de la leçon chargés.
            if (state is LessonDetailLoaded) {
              try {
                // On cherche le premier bloc de type 'quiz' dans la leçon.
                final quizBlock = state.lesson.contentBlocks.firstWhere(
                  (block) => block.blockType == ContentBlockType.quiz,
                );

                // On extrait l'ID du quiz et le nombre maximum de tentatives.
                final quizId = int.parse(quizBlock.content);
                final maxAttempts =
                    (quizBlock.metadata['max_attempts'] as num?)?.toInt() ?? -1;

                // On passe ces informations au widget qui gère l'affichage du quiz.
                return _QuizView(
                  quizId: quizId,
                  lessonId: lessonId,
                  maxAttempts: maxAttempts,
                );
              } catch (e) {
                // Si aucun bloc de quiz n'est trouvé dans la leçon.
                return const Center(
                  child: Text("Aucun quiz n'a été trouvé dans cette leçon."),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// Widget interne qui gère l'état et l'affichage du quiz lui-même.
///
/// Il est créé une fois que l'ID du quiz et les autres informations
/// nécessaires ont été extraites de la leçon.
class _QuizView extends StatelessWidget {
  final int quizId;
  final int lessonId;
  final int maxAttempts;

  const _QuizView({
    required this.quizId,
    required this.lessonId,
    required this.maxAttempts,
  });

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    // Étape 2: On fournit maintenant le QuizBloc avec les bons paramètres.
    return BlocProvider(
      create: (context) => sl<QuizBloc>()
        ..add(
          FetchQuiz(
            quizId: quizId,
            studentId: studentId,
            maxAttempts: maxAttempts,
          ),
        ),
      child: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          // Le corps de la page change en fonction de l'état du QuizBloc.
          return Scaffold(
            appBar: AppBar(
              // Le titre est mis à jour avec le vrai titre du quiz une fois chargé.
              title: Text(
                state.quiz.title.isNotEmpty
                    ? state.quiz.title
                    : 'Chargement...',
              ),
              // On s'assure que le bouton retour de l'AppBar n'est pas affiché
              // car la navigation est déjà gérée par la page principale.
              automaticallyImplyLeading: false,
            ),
            body: _buildBody(context, state),
            bottomNavigationBar: _buildBottomButton(context, state),
          );
        },
      ),
    );
  }

  /// Construit le corps principal de la page en fonction de l'état du quiz.
  Widget _buildBody(BuildContext context, QuizState state) {
    switch (state.status) {
      case QuizStatus.initial:
      case QuizStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case QuizStatus.loaded:
        if (!state.canAttemptQuiz) {
          return _buildAttemptsExceeded(context, state);
        }
        return _buildQuizForm(context, state);

      case QuizStatus.submitted:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Correction en cours...'),
            ],
          ),
        );

      case QuizStatus.showingResult:
        return _buildResultView(context, state);

      case QuizStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              state.error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }

  /// Construit le bouton en bas de page pour soumettre les réponses.
  Widget? _buildBottomButton(BuildContext context, QuizState state) {
    if (state.status == QuizStatus.loaded && state.canAttemptQuiz) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Valider mes réponses'),
          onPressed: () {
            final studentId = context.read<AuthenticationBloc>().state.user.id;
            context.read<QuizBloc>().add(
              // L'événement de soumission utilise `lessonId` qui est disponible ici.
              SubmitQuiz(studentId: studentId, lessonId: lessonId),
            );
          },
        ),
      );
    }
    return null;
  }

  /// Construit le formulaire du quiz avec les questions.
  Widget _buildQuizForm(BuildContext context, QuizState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.quiz.questions.length,
      itemBuilder: (context, index) {
        final question = state.quiz.questions[index];
        // On retourne le widget approprié en fonction du type de question.
        if (question.questionType == QuestionType.fill_in_the_blank) {
          return _FillInTheBlankInputCard(question: question);
        }
        // Par défaut, c'est un QCM.
        return _McqInputCard(
          question: question,
          groupValue: state.userAnswers[question.id],
        );
      },
    );
  }

  /// Affiche la vue des résultats après une tentative.
  Widget _buildResultView(BuildContext context, QuizState state) {
    final attempt = state.lastAttempt;
    if (attempt == null) {
      return const Center(
        child: Text("Erreur: Impossible d'afficher les résultats."),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Quiz Terminé !',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre score :',
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
              ],
            ),
          ),
        ),
        const Divider(height: 32),
        Text(
          'Correction détaillée',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // Affiche la correction pour chaque question.
        ...state.quiz.questions.map((question) {
          final userAnswer = attempt.answers[question.id];
          final isCorrect = _isAnswerCorrect(question, userAnswer);

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

        if (state.canAttemptQuiz) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Recommencer le Quiz"),
            onPressed: () => context.read<QuizBloc>().add(RestartQuiz()),
          ),
        ],
      ],
    );
  }

  /// Affiche un message lorsque l'utilisateur a épuisé ses tentatives.
  Widget _buildAttemptsExceeded(BuildContext context, QuizState state) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade800, size: 40),
              const SizedBox(height: 16),
              Text(
                "Tentatives épuisées",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.orange.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Vous avez atteint le nombre maximum de tentatives pour ce quiz. Vous pouvez consulter votre dernier résultat.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (state.lastAttempt != null)
                ElevatedButton(
                  onPressed: () => context.read<QuizBloc>().add(RestartQuiz()),
                  child: const Text("Voir mon dernier résultat"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fonction utilitaire pour vérifier si une réponse est correcte.
  bool _isAnswerCorrect(QuestionEntity question, dynamic userAnswer) {
    if (question.questionType == QuestionType.mcq) {
      final correctAnswerId = question.answers
          .firstWhere((a) => a.isCorrect)
          .id;
      return userAnswer == correctAnswerId;
    }
    if (question.questionType == QuestionType.fill_in_the_blank) {
      final userAnswerText = (userAnswer as String? ?? '').trim().toLowerCase();
      final correctAnswerText = (question.correctTextAnswer ?? '')
          .trim()
          .toLowerCase();
      return userAnswerText == correctAnswerText;
    }
    return false;
  }
}

// =======================================================================
// WIDGETS SPÉCIFIQUES POUR LES CARTES DE QUESTION (INPUTS)
// =======================================================================

/// Carte pour une question à choix multiples.
class _McqInputCard extends StatelessWidget {
  final QuestionEntity question;
  final int? groupValue;
  const _McqInputCard({required this.question, required this.groupValue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.text, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...question.answers.map((answer) {
              return RadioListTile<int>(
                title: Text(answer.text),
                value: answer.id,
                groupValue: groupValue,
                onChanged: (value) {
                  if (value != null) {
                    context.read<QuizBloc>().add(
                      AnswerSelected(questionId: question.id, answerId: value),
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Carte pour une question de type "texte à trous".
class _FillInTheBlankInputCard extends StatelessWidget {
  final QuestionEntity question;
  const _FillInTheBlankInputCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final parts = question.text.split('{{blank}}');
    final textBefore = parts.isNotEmpty ? parts[0] : '';
    final textAfter = parts.length > 1 ? parts[1] : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            if (textBefore.isNotEmpty)
              Text(textBefore, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              width: 150,
              child: TextField(
                onChanged: (value) {
                  context.read<QuizBloc>().add(
                    TextAnswerChanged(questionId: question.id, text: value),
                  );
                },
                decoration: const InputDecoration(
                  hintText: 'Votre réponse',
                  isDense: true,
                ),
              ),
            ),
            if (textAfter.isNotEmpty)
              Text(textAfter, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// WIDGETS SPÉCIFIQUES POUR LES CARTES DE QUESTION (RÉSULTATS)
// =======================================================================

/// Carte affichant le résultat d'une question QCM.
class _McqResultCard extends StatelessWidget {
  final QuestionEntity question;
  final int? selectedAnswerId;
  final bool isCorrect;
  const _McqResultCard({
    required this.question,
    this.selectedAnswerId,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(answer.text),
                  leading: Radio<int>(
                    value: answer.id,
                    groupValue: selectedAnswerId,
                    onChanged: null,
                  ),
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

/// Carte affichant le résultat d'une question "texte à trous".
class _FillInTheBlankResultCard extends StatelessWidget {
  final QuestionEntity question;
  final String userAnswer;
  final bool isCorrect;
  const _FillInTheBlankResultCard({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final parts = question.text.split('{{blank}}');
    final textBefore = parts.isNotEmpty ? parts[0] : '';
    final textAfter = parts.length > 1 ? parts[1] : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                if (textBefore.isNotEmpty)
                  Text(
                    textBefore,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                Text(
                  userAnswer.isNotEmpty ? userAnswer : '______',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                    decoration: isCorrect
                        ? TextDecoration.none
                        : TextDecoration.lineThrough,
                  ),
                ),
                if (textAfter.isNotEmpty)
                  Text(
                    textAfter,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              ],
            ),
            if (!isCorrect)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Bonne réponse : ${question.correctTextAnswer}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
