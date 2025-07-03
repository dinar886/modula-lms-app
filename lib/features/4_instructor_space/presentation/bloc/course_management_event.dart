import 'package:equatable/equatable.dart';

abstract class CourseManagementEvent extends Equatable {
  const CourseManagementEvent();
  @override
  List<Object> get props => [];
}

// Un seul événement pour la création, pour garder ce BLoC simple.
class CreateCourseRequested extends CourseManagementEvent {
  final String title;
  final String description;
  final double price;
  final String instructorId;

  const CreateCourseRequested({
    required this.title,
    required this.description,
    required this.price,
    required this.instructorId,
  });

  @override
  List<Object> get props => [title, description, price, instructorId];
}
