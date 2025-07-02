import 'package:equatable/equatable.dart';

abstract class CourseEditorState extends Equatable {
  const CourseEditorState();
  @override
  List<Object> get props => [];
}

// L'état initial, rien ne se passe.
class CourseEditorInitial extends CourseEditorState {}

// État pendant une opération (ajout, etc.)
class CourseEditorLoading extends CourseEditorState {}

// État de succès après une opération.
// On peut l'utiliser pour afficher un message ou rafraîchir une autre partie de l'UI.
class CourseEditorSuccess extends CourseEditorState {}

// État en cas d'erreur.
class CourseEditorFailure extends CourseEditorState {
  final String error;
  const CourseEditorFailure(this.error);
}
