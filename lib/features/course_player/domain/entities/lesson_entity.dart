import 'package:equatable/equatable.dart';

// On définit une énumération pour les types de leçons.
// C'est plus sûr que d'utiliser des chaînes de caractères.
enum LessonType { video, text, document, quiz, unknown }

class LessonEntity extends Equatable {
  final int id;
  final String title;
  final LessonType lessonType;
  // URL pour les leçons de type vidéo ou document.
  final String? contentUrl;
  // Contenu pour les leçons de type texte (supporte le Markdown).
  final String? contentText;

  const LessonEntity({
    required this.id,
    required this.title,
    required this.lessonType,
    this.contentUrl,
    this.contentText,
  });

  // Un constructeur "factory" pour créer une instance de LessonEntity à partir de données JSON.
  factory LessonEntity.fromJson(Map<String, dynamic> json) {
    return LessonEntity(
      id: json['id'],
      title: json['title'],
      lessonType: LessonEntity.fromString(json['lesson_type']),
      contentUrl: json['content_url'],
      contentText: json['content_text'],
    );
  }

  // Une méthode statique pour convertir la chaîne de caractères de l'API en une valeur de notre énumération.
  static LessonType fromString(String type) {
    switch (type) {
      case 'video':
        return LessonType.video;
      case 'text':
        return LessonType.text;
      case 'document':
        return LessonType.document;
      case 'quiz':
        return LessonType.quiz;
      default:
        return LessonType.unknown;
    }
  }

  // Les propriétés utilisées par Equatable pour comparer deux instances.
  @override
  List<Object?> get props => [id, title, lessonType, contentUrl, contentText];
}
