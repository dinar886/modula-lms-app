// lib/features/2_marketplace/presentation/bloc/course_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/features/2_marketplace/domain/usecases/get_courses.dart';
import 'package:modula_lms/features/2_marketplace/presentation/bloc/course_event.dart';
import 'package:modula_lms/features/2_marketplace/presentation/bloc/course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final GetCourses getCourses;

  CourseBloc({required this.getCourses}) : super(CourseInitial()) {
    // On enregistre un "handler" pour l'événement FetchCourses.
    on<FetchCourses>((event, emit) async {
      // Dès qu'on reçoit l'événement, on émet l'état de chargement.
      emit(CourseLoading());
      try {
        // On exécute le cas d'utilisation pour récupérer les cours.
        final courses = await getCourses();
        // Si tout s'est bien passé, on émet l'état de succès avec les données.
        emit(CourseLoaded(courses));
      } catch (e) {
        // En cas d'erreur, on émet l'état d'erreur.
        emit(const CourseError('Impossible de charger les cours.'));
      }
    });
  }
}
