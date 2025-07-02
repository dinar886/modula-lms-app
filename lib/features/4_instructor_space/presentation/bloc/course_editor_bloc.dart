import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'course_editor_event.dart';
import 'course_editor_state.dart';

class CourseEditorBloc extends Bloc<CourseEditorEvent, CourseEditorState> {
  final ApiClient apiClient;

  CourseEditorBloc({required this.apiClient}) : super(CourseEditorInitial()) {
    on<AddSection>(_onAddSection);
    on<AddLesson>(_onAddLesson);
    on<EditSection>(_onEditSection);
    on<DeleteSection>(_onDeleteSection);
    on<EditLesson>(_onEditLesson);
    on<DeleteLesson>(_onDeleteLesson);
  }

  Future<void> _onAddSection(
    AddSection event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/add_section.php',
        data: {'title': event.title, 'course_id': event.courseId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onAddLesson(
    AddLesson event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/add_lesson.php',
        data: {
          'title': event.title,
          'section_id': event.sectionId,
          'lesson_type': event.lessonType,
        },
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onEditSection(
    EditSection event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/edit_section.php',
        data: {'title': event.newTitle, 'section_id': event.sectionId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onDeleteSection(
    DeleteSection event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/delete_section.php',
        data: {'section_id': event.sectionId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onEditLesson(
    EditLesson event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/edit_lesson.php',
        data: {'title': event.newTitle, 'lesson_id': event.lessonId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onDeleteLesson(
    DeleteLesson event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/delete_lesson.php',
        data: {'lesson_id': event.lessonId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }
}
