import 'package:equatable/equatable.dart';

abstract class CourseContentEvent extends Equatable {
  const CourseContentEvent();
  @override
  List<Object> get props => [];
}

class FetchCourseContent extends CourseContentEvent {
  final String courseId;
  const FetchCourseContent(this.courseId);
}
