import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/quiz_entity.dart';

enum QuizEditorStatus { initial, loading, success, failure }

class QuizEditorState extends Equatable {
  final QuizEditorStatus status;
  final QuizEntity quiz;
  final String error;

  const QuizEditorState({
    this.status = QuizEditorStatus.initial,
    this.quiz = const QuizEntity(id: 0, title: '', questions: []),
    this.error = '',
  });

  QuizEditorState copyWith({
    QuizEditorStatus? status,
    QuizEntity? quiz,
    String? error,
  }) {
    return QuizEditorState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, quiz, error];
}
