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
    on<LessonContentChanged>(
      _onLessonContentChanged,
    ); // Enregistrement du nouvel événement
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
      // On réinitialise isDirty à false car on vient de charger les données fraîches
      emit(
        state.copyWith(
          status: LessonEditorStatus.success,
          lesson: lesson,
          isDirty: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: LessonEditorStatus.failure, error: e.toString()),
      );
    }
  }

  // NOUVEAU : Gestion du changement de contenu
  void _onLessonContentChanged(
    LessonContentChanged event,
    Emitter<LessonEditorState> emit,
  ) {
    // On met à jour le contenu de la leçon dans l'état et on passe isDirty à true
    final newLesson = state.lesson.copyWith(
      contentUrl: event.contentUrl,
      contentText: event.contentText,
    );
    emit(state.copyWith(lesson: newLesson, isDirty: true));
  }

  Future<void> _onSaveLessonContent(
    SaveLessonContent event,
    Emitter<LessonEditorState> emit,
  ) async {
    // On ne sauvegarde que si des changements ont été faits
    if (!state.isDirty) return;

    emit(state.copyWith(status: LessonEditorStatus.saving));
    try {
      await apiClient.post(
        '/api/v1/update_lesson_content.php',
        data: {
          'lesson_id': state.lesson.id,
          'content_url': state.lesson.contentUrl,
          'content_text': state.lesson.contentText,
        },
      );
      // Après la sauvegarde, on passe le statut à succès et on réinitialise isDirty
      emit(state.copyWith(status: LessonEditorStatus.success, isDirty: false));

      // Optionnel: Recharger les détails pour être sûr d'avoir la version la plus à jour.
      add(FetchLessonDetails(state.lesson.id));
    } catch (e) {
      emit(
        state.copyWith(status: LessonEditorStatus.failure, error: e.toString()),
      );
    }
  }
}
