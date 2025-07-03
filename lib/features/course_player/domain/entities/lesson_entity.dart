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

  // **LA CORRECTION EST ICI**
  // Ajout de la méthode `copyWith` pour permettre de créer une copie modifiée de l'objet.
  // Cela résout l'erreur dans le lesson_editor_bloc.
  LessonEntity copyWith({
    int? id,
    String? title,
    LessonType? lessonType,
    String? contentUrl,
    String? contentText,
  }) {
    return LessonEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      lessonType: lessonType ?? this.lessonType,
      // Si la nouvelle valeur est explicitement 'null', on la prend, sinon on garde l'ancienne.
      contentUrl: contentUrl,
      contentText: contentText,
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
