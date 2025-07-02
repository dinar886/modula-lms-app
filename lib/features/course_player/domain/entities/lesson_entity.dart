import 'package:equatable/equatable.dart';

enum LessonType { video, text, document, unknown }

class LessonEntity extends Equatable {
  final int id;
  final String title;
  final LessonType lessonType;
  // URL pour les vidéos ou documents
  final String? contentUrl;
  // Contenu pour les leçons textuelles
  final String? contentText;

  const LessonEntity({
    required this.id,
    required this.title,
    required this.lessonType,
    this.contentUrl,
    this.contentText,
  });

  // Constructeur pour créer une entité à partir du JSON.
  factory LessonEntity.fromJson(Map<String, dynamic> json) {
    return LessonEntity(
      id: json['id'],
      title: json['title'],
      lessonType: LessonEntity.fromString(json['lesson_type']),
      contentUrl: json['content_url'],
      contentText: json['content_text'],
    );
  }

  static LessonType fromString(String type) {
    switch (type) {
      case 'video':
        return LessonType.video;
      case 'text':
        return LessonType.text;
      case 'document':
        return LessonType.document;
      default:
        return LessonType.unknown;
    }
  }

  @override
  List<Object?> get props => [id, title, lessonType, contentUrl, contentText];
}
