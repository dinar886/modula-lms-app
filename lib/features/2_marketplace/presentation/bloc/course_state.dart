// lib/features/2_marketplace/presentation/bloc/course_state.dart

import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';

abstract class CourseState extends Equatable {
  const CourseState();
  @override
  List<Object> get props => [];
}

// État initial, avant que quoi que ce soit ne se passe.
class CourseInitial extends CourseState {}

// État de chargement, pendant qu'on attend les données.
class CourseLoading extends CourseState {}

// État de succès, quand on a reçu les données.
class CourseLoaded extends CourseState {
  final List<CourseEntity> courses;
  const CourseLoaded(this.courses);
  @override
  List<Object> get props => [courses];
}

// État d'erreur, si quelque chose s'est mal passé.
class CourseError extends CourseState {
  final String message;
  const CourseError(this.message);
  @override
  List<Object> get props => [message];
}
