import 'package:equatable/equatable.dart';

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

// NOUVEAU : Événement pour signaler un changement dans le contenu
class LessonContentChanged extends LessonEditorEvent {
  final String? contentUrl;
  final String? contentText;

  const LessonContentChanged({this.contentUrl, this.contentText});
}

// Pour sauvegarder les changements.
class SaveLessonContent extends LessonEditorEvent {}
