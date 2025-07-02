import 'package:equatable/equatable.dart';

abstract class LessonDetailEvent extends Equatable {
  const LessonDetailEvent();
  @override
  List<Object> get props => [];
}

class FetchLessonDetails extends LessonDetailEvent {
  final int lessonId;
  const FetchLessonDetails(this.lessonId);
}
