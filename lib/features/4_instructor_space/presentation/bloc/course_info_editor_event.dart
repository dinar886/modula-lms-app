// lib/features/4_instructor_space/presentation/bloc/course_info_editor_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Classe de base abstraite pour les événements.
abstract class CourseInfoEditorEvent extends Equatable {
  const CourseInfoEditorEvent();
  @override
  List<Object?> get props => [];
}

/// Événement pour charger les informations initiales du cours.
class LoadCourseInfo extends CourseInfoEditorEvent {
  final String courseId;
  const LoadCourseInfo(this.courseId);
}

/// Événement déclenché lorsque l'utilisateur modifie une valeur dans le formulaire.
class CourseInfoChanged extends CourseInfoEditorEvent {
  final String? title;
  final String? description;
  final double? price;
  final XFile? newImageFile;
  final Color? newColor;
  final bool clearImage;

  const CourseInfoChanged({
    this.title,
    this.description,
    this.price,
    this.newImageFile,
    this.newColor,
    this.clearImage = false,
  });
}

/// **NOUVEL ÉVÉNEMENT** : Déclenché pour supprimer l'image actuelle du cours.
class RemoveCourseImage extends CourseInfoEditorEvent {}

/// Événement pour sauvegarder toutes les modifications apportées au cours.
class SaveCourseInfoChanges extends CourseInfoEditorEvent {}
