import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/features/2_marketplace/domain/usecases/get_course_details.dart';
import 'course_detail_event.dart';
import 'course_detail_state.dart';

class CourseDetailBloc extends Bloc<CourseDetailEvent, CourseDetailState> {
  final GetCourseDetails getCourseDetails;

  CourseDetailBloc({required this.getCourseDetails})
    : super(CourseDetailInitial()) {
    on<FetchCourseDetails>((event, emit) async {
      emit(CourseDetailLoading());
      try {
        final course = await getCourseDetails(event.courseId);
        emit(CourseDetailLoaded(course));
      } catch (e) {
        emit(
          const CourseDetailError(
            'Impossible de charger les détails du cours.',
          ),
        );
      }
    });
  }
}
