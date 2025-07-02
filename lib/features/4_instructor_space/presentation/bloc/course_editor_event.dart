import 'package:equatable/equatable.dart';

abstract class CourseEditorEvent extends Equatable {
  const CourseEditorEvent();
  @override
  List<Object> get props => [];
}

// Événements d'ajout
class AddSection extends CourseEditorEvent {
  final String title;
  final String courseId;
  const AddSection({required this.title, required this.courseId});
}

class AddLesson extends CourseEditorEvent {
  final String title;
  final int sectionId;
  final String lessonType;
  const AddLesson({
    required this.title,
    required this.sectionId,
    required this.lessonType,
  });
}

// Nouveaux événements de modification
class EditSection extends CourseEditorEvent {
  final String newTitle;
  final int sectionId;
  const EditSection({required this.newTitle, required this.sectionId});
}

class EditLesson extends CourseEditorEvent {
  final String newTitle;
  final int lessonId;
  const EditLesson({required this.newTitle, required this.lessonId});
}

// Nouveaux événements de suppression
class DeleteSection extends CourseEditorEvent {
  final int sectionId;
  const DeleteSection(this.sectionId);
}

class DeleteLesson extends CourseEditorEvent {
  final int lessonId;
  const DeleteLesson(this.lessonId);
}
