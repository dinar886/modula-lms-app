import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/domain/entities/quiz_entity.dart';
import 'quiz_editor_event.dart';
import 'quiz_editor_state.dart';

class QuizEditorBloc extends Bloc<QuizEditorEvent, QuizEditorState> {
  final ApiClient apiClient;

  QuizEditorBloc({required this.apiClient}) : super(const QuizEditorState()) {
    on<FetchQuizForEditing>(_onFetchQuizForEditing);
    on<AddQuestion>(_onAddQuestion);
    on<DeleteQuestion>(_onDeleteQuestion);
    on<AddAnswer>(_onAddAnswer);
    on<DeleteAnswer>(_onDeleteAnswer);
    on<SetCorrectAnswer>(_onSetCorrectAnswer);
  }

  Future<void> _onFetchQuizForEditing(
    FetchQuizForEditing event,
    Emitter<QuizEditorState> emit,
  ) async {
    emit(state.copyWith(status: QuizEditorStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_quiz_details.php',
        queryParameters: {'lesson_id': event.lessonId},
      );
      final quiz = QuizEntity.fromJson(response.data);
      emit(state.copyWith(status: QuizEditorStatus.success, quiz: quiz));
    } catch (e) {
      emit(
        state.copyWith(status: QuizEditorStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onAddQuestion(
    AddQuestion event,
    Emitter<QuizEditorState> emit,
  ) async {
    await apiClient.post(
      '/api/v1/add_question.php',
      data: {'quiz_id': event.quizId, 'question_text': event.questionText},
    );
  }

  Future<void> _onDeleteQuestion(
    DeleteQuestion event,
    Emitter<QuizEditorState> emit,
  ) async {
    await apiClient.post(
      '/api/v1/delete_question.php',
      data: {'question_id': event.questionId},
    );
  }

  Future<void> _onAddAnswer(
    AddAnswer event,
    Emitter<QuizEditorState> emit,
  ) async {
    await apiClient.post(
      '/api/v1/add_answer.php',
      data: {'question_id': event.questionId, 'answer_text': event.answerText},
    );
  }

  Future<void> _onDeleteAnswer(
    DeleteAnswer event,
    Emitter<QuizEditorState> emit,
  ) async {
    await apiClient.post(
      '/api/v1/delete_answer.php',
      data: {'answer_id': event.answerId},
    );
  }

  Future<void> _onSetCorrectAnswer(
    SetCorrectAnswer event,
    Emitter<QuizEditorState> emit,
  ) async {
    await apiClient.post(
      '/api/v1/set_correct_answer.php',
      data: {'question_id': event.questionId, 'answer_id': event.answerId},
    );
  }
}
