import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';

class SectionEntity extends Equatable {
  final int id;
  final String title;
  final List<LessonEntity> lessons;

  const SectionEntity({
    required this.id,
    required this.title,
    required this.lessons,
  });

  @override
  List<Object?> get props => [id, title, lessons];
}
