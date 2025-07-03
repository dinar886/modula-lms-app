import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'course_management_event.dart';
import 'course_management_state.dart';

class CourseManagementBloc
    extends Bloc<CourseManagementEvent, CourseManagementState> {
  final ApiClient apiClient;

  CourseManagementBloc({required this.apiClient})
    : super(const CourseManagementState()) {
    on<CreateCourseRequested>(_onCreateCourseRequested);
  }

  Future<void> _onCreateCourseRequested(
    CreateCourseRequested event,
    Emitter<CourseManagementState> emit,
  ) async {
    // On passe à l'état de chargement en utilisant copyWith
    emit(state.copyWith(status: CourseManagementStatus.loading));
    try {
      // On appelle l'API avec les bonnes données
      await apiClient.post(
        '/api/v1/create_course.php',
        data: {
          'title': event.title,
          'description': event.description,
          'price': event.price,
          'instructor_id': event.instructorId,
        },
      );
      // On passe à l'état de succès
      emit(state.copyWith(status: CourseManagementStatus.success));
    } catch (e) {
      // En cas d'erreur, on passe à l'état d'échec
      emit(
        state.copyWith(
          status: CourseManagementStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}
