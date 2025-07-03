import 'package:equatable/equatable.dart';

abstract class CourseInfoEditorEvent extends Equatable {
  const CourseInfoEditorEvent();
  @override
  List<Object?> get props => [];
}

// Pour charger les informations initiales du cours
class LoadCourseInfo extends CourseInfoEditorEvent {
  final int courseId;
  const LoadCourseInfo(this.courseId);
}

// Pour signaler un changement dans le formulaire
class CourseInfoChanged extends CourseInfoEditorEvent {
  final String? title;
  final String? description;
  final double? price;
  final String? imageUrl;

  const CourseInfoChanged({
    this.title,
    this.description,
    this.price,
    this.imageUrl,
  });
}

// Pour sauvegarder les modifications
class SaveCourseInfoChanges extends CourseInfoEditorEvent {}
