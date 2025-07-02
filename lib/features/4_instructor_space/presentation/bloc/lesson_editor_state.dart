import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';

// On utilise un enum pour gérer plus finement les états de la page.
enum LessonEditorStatus { initial, loading, success, failure, saving }

class LessonEditorState extends Equatable {
  final LessonEditorStatus status;
  final LessonEntity lesson;
  final String error;

  const LessonEditorState({
    this.status = LessonEditorStatus.initial,
    this.lesson = const LessonEntity(
      id: 0,
      title: '',
      lessonType: LessonType.unknown,
    ),
    this.error = '',
  });

  // Méthode 'copyWith' pour créer une nouvelle instance de l'état
  // en ne changeant que les propriétés nécessaires. C'est une pratique courante avec BLoC.
  LessonEditorState copyWith({
    LessonEditorStatus? status,
    LessonEntity? lesson,
    String? error,
  }) {
    return LessonEditorState(
      status: status ?? this.status,
      lesson: lesson ?? this.lesson,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, lesson, error];
}
