// lib/features/2_marketplace/presentation/bloc/course_event.dart

import 'package:equatable/equatable.dart';

abstract class CourseEvent extends Equatable {
  const CourseEvent();
  @override
  List<Object> get props => [];
}

// L'unique événement pour l'instant : "Va chercher les cours".
class FetchCourses extends CourseEvent {}
