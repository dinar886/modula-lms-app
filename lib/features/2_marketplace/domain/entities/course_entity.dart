// lib/features/2_marketplace/domain/entities/course_entity.dart
import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String imageUrl;
  final double price;

  const CourseEntity({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    required this.imageUrl,
    required this.price,
  });

  // Ajout de la méthode copyWith
  CourseEntity copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? imageUrl,
    double? price,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [id, title, author, description, imageUrl, price];
}
