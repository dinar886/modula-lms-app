import 'package:equatable/equatable.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();
  @override
  List<Object> get props => [];
}

// Pour charger le quiz
class FetchQuiz extends QuizEvent {
  final int lessonId;
  const FetchQuiz(this.lessonId);
}

// Quand l'utilisateur choisit une réponse
class AnswerSelected extends QuizEvent {
  final int questionId;
  final int answerId;
  const AnswerSelected({required this.questionId, required this.answerId});
}

// Quand l'utilisateur soumet le quiz
class SubmitQuiz extends QuizEvent {}
