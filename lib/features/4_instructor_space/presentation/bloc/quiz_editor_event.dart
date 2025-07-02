import 'package:equatable/equatable.dart';

abstract class QuizEditorEvent extends Equatable {
  const QuizEditorEvent();
  @override
  List<Object> get props => [];
}

class FetchQuizForEditing extends QuizEditorEvent {
  final int lessonId;
  const FetchQuizForEditing(this.lessonId);
}

class AddQuestion extends QuizEditorEvent {
  final int quizId;
  final String questionText;
  const AddQuestion({required this.quizId, required this.questionText});
}

class DeleteQuestion extends QuizEditorEvent {
  final int questionId;
  const DeleteQuestion(this.questionId);
}

class AddAnswer extends QuizEditorEvent {
  final int questionId;
  final String answerText;
  const AddAnswer({required this.questionId, required this.answerText});
}

class DeleteAnswer extends QuizEditorEvent {
  final int answerId;
  const DeleteAnswer(this.answerId);
}

class SetCorrectAnswer extends QuizEditorEvent {
  final int questionId;
  final int answerId;
  const SetCorrectAnswer({required this.questionId, required this.answerId});
}
