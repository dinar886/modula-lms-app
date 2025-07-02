import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/question_entity.dart';

class QuizEntity extends Equatable {
  final int id;
  final String title;
  final String? description;
  final List<QuestionEntity> questions;

  const QuizEntity({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
  });

  factory QuizEntity.fromJson(Map<String, dynamic> json) {
    return QuizEntity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      questions: (json['questions'] as List)
          .map((questionJson) => QuestionEntity.fromJson(questionJson))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, title, description, questions];
}
