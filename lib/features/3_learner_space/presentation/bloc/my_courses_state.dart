import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';

abstract class MyCoursesState extends Equatable {
  const MyCoursesState();
  @override
  List<Object> get props => [];
}

class MyCoursesInitial extends MyCoursesState {}

class MyCoursesLoading extends MyCoursesState {}

class MyCoursesLoaded extends MyCoursesState {
  final List<CourseEntity> courses;
  const MyCoursesLoaded(this.courses);
}

class MyCoursesError extends MyCoursesState {
  final String message;
  const MyCoursesError(this.message);
}
