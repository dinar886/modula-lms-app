// lib/features/4_instructor_space/presentation/bloc/course_management_bloc.dart
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
    emit(state.copyWith(status: CourseManagementStatus.loading));
    try {
      // **MODIFIÉ** : On prépare les données pour l'envoi multipart.
      final data = {
        'title': event.title,
        'description': event.description,
        'price': event.price,
        'instructor_id': event.instructorId,
        // On envoie la couleur si elle est définie, au format HEX.
        if (event.color != null)
          'color':
              '#${event.color!.value.toRadixString(16).substring(2).toUpperCase()}',
      };

      // **MODIFIÉ** : On utilise la méthode `postMultipart` de notre ApiClient.
      // Elle est capable de gérer à la fois les champs de texte et l'upload de fichier.
      await apiClient.postMultipart(
        '/api/v1/create_course.php',
        data: data,
        imageFile: event.imageFile,
      );

      emit(state.copyWith(status: CourseManagementStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseManagementStatus.failure,
          error: "Erreur lors de la création : ${e.toString()}",
        ),
      );
    }
  }
}
