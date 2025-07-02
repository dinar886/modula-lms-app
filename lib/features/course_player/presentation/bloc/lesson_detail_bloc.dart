import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/lesson_detail_event.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/lesson_detail_state.dart';

class LessonDetailBloc extends Bloc<LessonDetailEvent, LessonDetailState> {
  final ApiClient apiClient;

  LessonDetailBloc({required this.apiClient}) : super(LessonDetailInitial()) {
    on<FetchLessonDetails>((event, emit) async {
      emit(LessonDetailLoading());
      try {
        final response = await apiClient.get(
          '/api/v1/get_lesson_details.php',
          queryParameters: {'lesson_id': event.lessonId},
        );
        final lesson = LessonEntity.fromJson(response.data);
        emit(LessonDetailLoaded(lesson));
      } catch (e) {
        emit(LessonDetailError(e.toString()));
      }
    });
  }
}
