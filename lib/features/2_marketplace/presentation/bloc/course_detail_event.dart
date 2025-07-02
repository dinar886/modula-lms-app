import 'package:equatable/equatable.dart';

abstract class CourseDetailEvent extends Equatable {
  const CourseDetailEvent();
  @override
  List<Object> get props => [];
}

class FetchCourseDetails extends CourseDetailEvent {
  final String courseId;
  const FetchCourseDetails(this.courseId);
  @override
  List<Object> get props => [courseId];
}
