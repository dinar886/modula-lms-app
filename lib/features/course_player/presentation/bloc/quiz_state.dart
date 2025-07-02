import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/quiz_entity.dart';

enum QuizStatus { initial, loading, loaded, submitted, failure }

class QuizState extends Equatable {
  final QuizStatus status;
  final QuizEntity quiz;
  // Map pour stocker les réponses de l'utilisateur: {questionId: answerId}
  final Map<int, int> userAnswers;
  final double? score;
  final String error;

  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz = const QuizEntity(id: 0, title: '', questions: []),
    this.userAnswers = const {},
    this.score,
    this.error = '',
  });

  QuizState copyWith({
    QuizStatus? status,
    QuizEntity? quiz,
    Map<int, int>? userAnswers,
    double? score,
    String? error,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      userAnswers: userAnswers ?? this.userAnswers,
      score:
          score, // Le score est intentionnellement non hérité pour être recalculé
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, quiz, userAnswers, score, error];
}
