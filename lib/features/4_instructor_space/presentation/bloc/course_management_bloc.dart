import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'course_management_event.dart';
import 'course_management_state.dart';

class CourseManagementBloc
    extends Bloc<CourseManagementEvent, CourseManagementState> {
  final ApiClient apiClient;

  CourseManagementBloc({required this.apiClient})
    : super(CourseManagementInitial()) {
    on<CreateCourseRequested>((event, emit) async {
      emit(CourseManagementLoading());
      try {
        await apiClient.post(
          '/api/v1/create_course.php',
          data: {
            'title': event.title,
            'description': event.description,
            'price': event.price,
            'instructor_id': event.instructorId,
          },
        );
        emit(CourseManagementSuccess());
      } catch (e) {
        emit(CourseManagementFailure(e.toString()));
      }
    });
  }
}
