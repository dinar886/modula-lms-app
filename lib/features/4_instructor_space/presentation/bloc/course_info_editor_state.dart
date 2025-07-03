// lib/features/4_instructor_space/presentation/bloc/course_info_editor_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';

/// Énumération des différents statuts possibles pour l'éditeur d'informations du cours.
enum CourseInfoEditorStatus {
  initial,
  loading,
  loaded,
  saving,
  success,
  failure,
}

class CourseInfoEditorState extends Equatable {
  final CourseInfoEditorStatus status;
  final CourseEntity course; // Les données actuelles du cours
  final String error; // Message d'erreur en cas d'échec
  final bool isDirty; // Indique si le formulaire a été modifié
  final XFile?
  newImageFile; // Le nouveau fichier image sélectionné par l'utilisateur
  final Color? newColor; // La nouvelle couleur sélectionnée pour le placeholder

  const CourseInfoEditorState({
    this.status = CourseInfoEditorStatus.initial,
    this.course = const CourseEntity(
      id: '',
      title: '',
      author: '',
      imageUrl: '',
      price: 0,
    ),
    this.error = '',
    this.isDirty = false,
    this.newImageFile,
    this.newColor,
  });

  /// Méthode pour créer une copie de l'état avec des valeurs mises à jour.
  CourseInfoEditorState copyWith({
    CourseInfoEditorStatus? status,
    CourseEntity? course,
    String? error,
    bool? isDirty,
    XFile? newImageFile,
    Color? newColor,
    bool clearImage =
        false, // Flag pour permettre de supprimer l'image sélectionnée
  }) {
    return CourseInfoEditorState(
      status: status ?? this.status,
      course: course ?? this.course,
      error: error ?? this.error,
      isDirty: isDirty ?? this.isDirty,
      newImageFile: clearImage ? null : newImageFile ?? this.newImageFile,
      newColor: newColor ?? this.newColor,
    );
  }

  @override
  List<Object?> get props => [
    status,
    course,
    error,
    isDirty,
    newImageFile,
    newColor,
  ];
}
