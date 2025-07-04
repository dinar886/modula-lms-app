// lib/features/4_instructor_space/presentation/bloc/course_management_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

abstract class CourseManagementEvent extends Equatable {
  const CourseManagementEvent();
  @override
  List<Object?> get props => [];
}

// L'événement de création de cours est maintenant enrichi.
class CreateCourseRequested extends CourseManagementEvent {
  final String title;
  final String description;
  final double price;
  final String instructorId;
  // **NOUVEAU** : Le fichier image sélectionné (peut être null).
  final XFile? imageFile;
  // **NOUVEAU** : La couleur de fond pour le placeholder (peut être null).
  final Color? color;

  const CreateCourseRequested({
    required this.title,
    required this.description,
    required this.price,
    required this.instructorId,
    this.imageFile,
    this.color,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    price,
    instructorId,
    imageFile,
    color,
  ];
}
