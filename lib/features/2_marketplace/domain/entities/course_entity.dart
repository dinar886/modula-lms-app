// lib/features/2_marketplace/domain/entities/course_entity.dart
import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? description; // On ajoute la description (optionnelle ici)
  final String imageUrl;
  final double price;

  const CourseEntity({
    required this.id,
    required this.title,
    required this.author,
    this.description, // Le champ est optionnel
    required this.imageUrl,
    required this.price,
  });

  @override
  List<Object?> get props => [id, title, author, description, imageUrl, price];
}
