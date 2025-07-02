import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';

abstract class LessonDetailState extends Equatable {
  const LessonDetailState();
  @override
  List<Object> get props => [];
}

class LessonDetailInitial extends LessonDetailState {}

class LessonDetailLoading extends LessonDetailState {}

class LessonDetailLoaded extends LessonDetailState {
  final LessonEntity lesson;
  const LessonDetailLoaded(this.lesson);
}

class LessonDetailError extends LessonDetailState {
  final String message;
  const LessonDetailError(this.message);
}
