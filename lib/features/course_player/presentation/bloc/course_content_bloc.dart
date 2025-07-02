import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';
import 'package:modula_lms/features/course_player/domain/entities/section_entity.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/course_content_event.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/course_content_state.dart';

class CourseContentBloc extends Bloc<CourseContentEvent, CourseContentState> {
  final ApiClient apiClient;

  CourseContentBloc({required this.apiClient}) : super(CourseContentInitial()) {
    on<FetchCourseContent>(_onFetchCourseContent);
  }

  Future<void> _onFetchCourseContent(
    FetchCourseContent event,
    Emitter<CourseContentState> emit,
  ) async {
    emit(CourseContentLoading());
    try {
      final response = await apiClient.get(
        '/api/v1/get_course_content.php',
        queryParameters: {'course_id': event.courseId},
      );

      // On décode manuellement la réponse JSON ici.
      final List<SectionEntity> sections = (response.data as List).map((
        sectionData,
      ) {
        final List<LessonEntity> lessons = (sectionData['lessons'] as List).map(
          (lessonData) {
            return LessonEntity(
              id: lessonData['id'],
              title: lessonData['title'],
              lessonType: LessonEntity.fromString(lessonData['lesson_type']),
            );
          },
        ).toList();

        return SectionEntity(
          id: sectionData['id'],
          title: sectionData['title'],
          lessons: lessons,
        );
      }).toList();

      emit(CourseContentLoaded(sections));
    } catch (e) {
      emit(CourseContentError(e.toString()));
    }
  }
}
