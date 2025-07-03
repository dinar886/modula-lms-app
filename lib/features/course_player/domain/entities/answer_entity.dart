// lib/features/course_player/domain/entities/answer_entity.dart
import 'package:equatable/equatable.dart';

class AnswerEntity extends Equatable {
  final int id;
  final String text;
  final bool isCorrect;

  const AnswerEntity({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory AnswerEntity.fromJson(Map<String, dynamic> json) {
    return AnswerEntity(
      id: json['id'],
      text: json['answer_text'],
      isCorrect: json['is_correct'],
    );
  }

  // Ajout de la méthode toJson
  Map<String, dynamic> toJson() {
    return {'answer_text': text, 'is_correct': isCorrect};
  }

  // Ajout de la méthode copyWith
  AnswerEntity copyWith({int? id, String? text, bool? isCorrect}) {
    return AnswerEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  List<Object?> get props => [id, text, isCorrect];
}
