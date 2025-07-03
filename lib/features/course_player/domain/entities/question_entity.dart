// lib/features/course_player/domain/entities/question_entity.dart
import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/answer_entity.dart';

class QuestionEntity extends Equatable {
  final int id;
  final String text;
  final List<AnswerEntity> answers;

  const QuestionEntity({
    required this.id,
    required this.text,
    required this.answers,
  });

  factory QuestionEntity.fromJson(Map<String, dynamic> json) {
    return QuestionEntity(
      id: json['id'],
      text: json['question_text'],
      answers: (json['answers'] as List)
          .map((answerJson) => AnswerEntity.fromJson(answerJson))
          .toList(),
    );
  }

  // Ajout de la méthode toJson
  Map<String, dynamic> toJson() {
    return {
      // On n'envoie pas l'ID car il sera regénéré côté serveur pour éviter les conflits
      'question_text': text,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }

  // Ajout de la méthode copyWith
  QuestionEntity copyWith({
    int? id,
    String? text,
    List<AnswerEntity>? answers,
  }) {
    return QuestionEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      answers: answers ?? this.answers,
    );
  }

  @override
  List<Object?> get props => [id, text, answers];
}
