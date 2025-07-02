import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/domain/entities/quiz_entity.dart';
// ** LA CORRECTION EST ICI **
// On s'assure que les chemins d'importation sont corrects.
import 'package:modula_lms/features/course_player/presentation/bloc/quiz_event.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final ApiClient apiClient;

  QuizBloc({required this.apiClient}) : super(const QuizState()) {
    on<FetchQuiz>(_onFetchQuiz);
    on<AnswerSelected>(_onAnswerSelected);
    on<SubmitQuiz>(_onSubmitQuiz);
  }

  Future<void> _onFetchQuiz(FetchQuiz event, Emitter<QuizState> emit) async {
    // Passe à l'état de chargement.
    emit(state.copyWith(status: QuizStatus.loading));
    try {
      // Fait l'appel API pour récupérer les données du quiz.
      final response = await apiClient.get(
        '/api/v1/get_quiz_details.php',
        queryParameters: {'lesson_id': event.lessonId},
      );
      // Crée un objet QuizEntity à partir du JSON reçu.
      final quiz = QuizEntity.fromJson(response.data);
      // Passe à l'état de succès avec les données du quiz.
      emit(state.copyWith(status: QuizStatus.loaded, quiz: quiz));
    } catch (e) {
      // En cas d'erreur, passe à l'état d'échec.
      emit(state.copyWith(status: QuizStatus.failure, error: e.toString()));
    }
  }

  void _onAnswerSelected(AnswerSelected event, Emitter<QuizState> emit) {
    // Crée une nouvelle map modifiable à partir des réponses actuelles de l'utilisateur.
    final updatedAnswers = Map<int, int>.from(state.userAnswers);
    // Met à jour ou ajoute la réponse pour la question concernée.
    updatedAnswers[event.questionId] = event.answerId;
    // Émet un nouvel état avec la map de réponses mise à jour.
    emit(state.copyWith(userAnswers: updatedAnswers));
  }

  void _onSubmitQuiz(SubmitQuiz event, Emitter<QuizState> emit) {
    int correctAnswersCount = 0;
    // On parcourt chaque question du quiz.
    for (var question in state.quiz.questions) {
      // On trouve la bonne réponse pour cette question dans la liste des options.
      final correctAnswer = question.answers.firstWhere(
        (answer) => answer.isCorrect,
      );
      // On vérifie si la réponse de l'utilisateur pour cette question correspond à la bonne réponse.
      if (state.userAnswers[question.id] == correctAnswer.id) {
        correctAnswersCount++;
      }
    }
    // On calcule le score en pourcentage.
    final score = (correctAnswersCount / state.quiz.questions.length) * 100;
    // On passe à l'état "soumis" en enregistrant le score.
    emit(state.copyWith(status: QuizStatus.submitted, score: score));
  }
}
