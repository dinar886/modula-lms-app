import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/section_entity.dart';

abstract class CourseContentState extends Equatable {
  const CourseContentState();
  @override
  List<Object> get props => [];
}

class CourseContentInitial extends CourseContentState {}

class CourseContentLoading extends CourseContentState {}

class CourseContentLoaded extends CourseContentState {
  final List<SectionEntity> sections;
  const CourseContentLoaded(this.sections);
}

class CourseContentError extends CourseContentState {
  final String message;
  const CourseContentError(this.message);
}
