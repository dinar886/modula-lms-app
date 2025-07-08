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
    // On récupère l'ID de l'utilisateur pour le passer au BLoC.
    final userId = context.read<AuthenticationBloc>().state.user.id;

    return BlocProvider(
      create: (context) =>
          sl<QuizBloc>()..add(FetchQuiz(lessonId: lessonId, studentId: userId)),
      child: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          // L'AppBar affiche le titre du quiz une fois chargé.
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.quiz.title.isNotEmpty
                    ? state.quiz.title
                    : 'Chargement du Quiz...',
              ),
            ),
            // Le corps de la page change en fonction de l'état du BLoC.
            body: _buildBody(context, state),
            // Le bouton de soumission n'apparaît que lorsque le quiz est prêt à être soumis.
            bottomNavigationBar: _buildBottomButton(context, state),
          );
        },
      ),
    );
  }

  /// Construit le corps principal de la page en fonction de l'état du quiz.
  Widget _buildBody(BuildContext context, QuizState state) {
    switch (state.status) {
      // Cas 1: Chargement initial du quiz.
      case QuizStatus.initial:
      case QuizStatus.loading:
        return const Center(child: CircularProgressIndicator());

      // Cas 2: Le quiz est chargé et l'utilisateur peut répondre.
      case QuizStatus.loaded:
        // Si l'utilisateur n'a plus de tentatives, on affiche un message.
        if (!state.canAttemptQuiz) {
          return _buildAttemptsExceeded(context);
        }
        // Sinon, on affiche le formulaire du quiz.
        return _buildQuizForm(context, state);

      // Cas 3: Le quiz a été soumis, en attente de la réponse du serveur.
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

      // Cas 4: NOUVEAU - Affiche la page des résultats détaillés.
      case QuizStatus.showingResult:
        return _buildResultView(context, state);

      // Cas 5: Une erreur est survenue.
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

  /// Construit le bouton en bas de page (uniquement le bouton "Soumettre").
  Widget? _buildBottomButton(BuildContext context, QuizState state) {
    // Le bouton n'est visible que si le quiz est chargé et peut être tenté.
    if (state.status == QuizStatus.loaded && state.canAttemptQuiz) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Valider mes réponses'),
          onPressed: () {
            // Au clic, on envoie l'événement de soumission au BLoC.
            final studentId = context.read<AuthenticationBloc>().state.user.id;
            context.read<QuizBloc>().add(
              SubmitQuiz(studentId: studentId, lessonId: lessonId),
            );
          },
        ),
      );
    }
    // Dans tous les autres cas, pas de bouton.
    return null;
  }

  /// Affiche le formulaire du quiz avec les questions et les réponses.
  Widget _buildQuizForm(BuildContext context, QuizState state) {
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
                // Texte de la question
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                // Liste des réponses possibles sous forme de boutons radio
                ...question.answers.map((answer) {
                  return RadioListTile<int>(
                    title: Text(answer.text),
                    value: answer.id,
                    groupValue: state.userAnswers[question.id],
                    onChanged: (value) {
                      // Quand une réponse est sélectionnée, on notifie le BLoC.
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
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// NOUVEAU WIDGET: Affiche la vue des résultats après soumission.
  Widget _buildResultView(BuildContext context, QuizState state) {
    final attempt = state.lastAttempt;
    if (attempt == null) {
      return const Center(
        child: Text("Erreur: Impossible d'afficher les résultats."),
      );
    }

    // On utilise un ListView pour que l'écran soit scrollable.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Section du score
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
                // Affichage du score sur 20
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

        // Section de la correction détaillée
        Text(
          'Correction détaillée',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // On boucle sur chaque question pour afficher la correction.
        ...state.quiz.questions.map((question) {
          final selectedAnswerId = attempt.answers[question.id];
          final correctAnswer = question.answers.firstWhere((a) => a.isCorrect);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texte de la question
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // On boucle sur chaque réponse possible pour l'afficher.
                  ...question.answers.map((answer) {
                    final isSelected = answer.id == selectedAnswerId;
                    final isCorrect = answer.isCorrect;

                    Color? tileColor; // Couleur de fond de la case
                    Icon? trailingIcon; // Icône à droite (check ou cancel)

                    // Si la réponse est la bonne, on la colore en vert.
                    if (isCorrect) {
                      tileColor = Colors.green.withOpacity(0.15);
                      trailingIcon = const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      );
                    }
                    // Si l'utilisateur a sélectionné cette réponse ET qu'elle est fausse...
                    if (isSelected && !isCorrect) {
                      // ...on la colore en rouge.
                      tileColor = Colors.red.withOpacity(0.15);
                      trailingIcon = const Icon(
                        Icons.cancel,
                        color: Colors.red,
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(answer.text),
                        // Le bouton radio montre la réponse de l'utilisateur.
                        leading: Radio<int>(
                          value: answer.id,
                          groupValue: selectedAnswerId,
                          onChanged:
                              null, // Désactivé car on est en mode résultat
                        ),
                        trailing: trailingIcon,
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),

        // Bouton pour recommencer, si autorisé.
        if (state.canAttemptQuiz) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Recommencer le Quiz"),
            onPressed: () {
              // Envoie l'événement pour réinitialiser le quiz.
              context.read<QuizBloc>().add(RestartQuiz());
            },
          ),
        ],
      ],
    );
  }

  /// Affiche un message si l'utilisateur a épuisé ses tentatives.
  Widget _buildAttemptsExceeded(BuildContext context) {
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
              Text(
                "Vous avez déjà atteint le nombre maximum de tentatives pour ce quiz. Vous pouvez consulter votre dernier résultat.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Au clic, on force l'affichage des résultats de la dernière tentative.
                  final userId = context
                      .read<AuthenticationBloc>()
                      .state
                      .user
                      .id;
                  context.read<QuizBloc>().add(
                    FetchQuiz(lessonId: lessonId, studentId: userId),
                  );
                },
                child: const Text("Voir mon dernier résultat"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
