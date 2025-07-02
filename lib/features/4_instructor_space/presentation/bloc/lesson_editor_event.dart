import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';

abstract class LessonEditorEvent extends Equatable {
  const LessonEditorEvent();
  @override
  List<Object?> get props => [];
}

// Pour récupérer les détails actuels de la leçon.
class FetchLessonDetails extends LessonEditorEvent {
  final int lessonId;
  const FetchLessonDetails(this.lessonId);
}

// Pour sauvegarder les changements.
class SaveLessonContent extends LessonEditorEvent {
  final int lessonId;
  final String? contentUrl;
  final String? contentText;

  const SaveLessonContent({
    required this.lessonId,
    this.contentUrl,
    this.contentText,
  });
}
