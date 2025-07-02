import 'package:equatable/equatable.dart';

abstract class MyCoursesEvent extends Equatable {
  const MyCoursesEvent();
  @override
  List<Object> get props => [];
}

class FetchMyCourses extends MyCoursesEvent {
  final String userId;
  const FetchMyCourses(this.userId);
}
