// lib/features/2_marketplace/data/models/course_model.dart
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';

class CourseModel extends CourseEntity {
  const CourseModel({
    required super.id,
    required super.title,
    required super.author,
    super.description,
    required super.imageUrl,
    required super.price,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'].toString(),
      title: json['title'],
      author: json['author'],
      description: json['description'], // On lit la nouvelle clé JSON
      imageUrl: json['image_url'],
      price: (json['price'] as num).toDouble(),
    );
  }
}
