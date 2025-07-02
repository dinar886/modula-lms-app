import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';
import 'lesson_editor_event.dart';
import 'lesson_editor_state.dart';

class LessonEditorBloc extends Bloc<LessonEditorEvent, LessonEditorState> {
  final ApiClient apiClient;

  LessonEditorBloc({required this.apiClient})
    : super(const LessonEditorState()) {
    on<FetchLessonDetails>(_onFetchLessonDetails);
    on<SaveLessonContent>(_onSaveLessonContent);
  }

  Future<void> _onFetchLessonDetails(
    FetchLessonDetails event,
    Emitter<LessonEditorState> emit,
  ) async {
    emit(state.copyWith(status: LessonEditorStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_lesson_details.php',
        queryParameters: {'lesson_id': event.lessonId},
      );
      final lesson = LessonEntity.fromJson(response.data);
      emit(state.copyWith(status: LessonEditorStatus.success, lesson: lesson));
    } catch (e) {
      emit(
        state.copyWith(status: LessonEditorStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onSaveLessonContent(
    SaveLessonContent event,
    Emitter<LessonEditorState> emit,
  ) async {
    emit(state.copyWith(status: LessonEditorStatus.saving));
    try {
      await apiClient.post(
        '/api/v1/update_lesson_content.php',
        data: {
          'lesson_id': event.lessonId,
          'content_url': event.contentUrl,
          'content_text': event.contentText,
        },
      );
      // On recharge les détails pour avoir la version la plus à jour.
      add(FetchLessonDetails(event.lessonId));
    } catch (e) {
      emit(
        state.copyWith(status: LessonEditorStatus.failure, error: e.toString()),
      );
    }
  }
}
