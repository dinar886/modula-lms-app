// lib/features/course_player/course_player_logic.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'dart:convert';

//==============================================================================
// ENTITIES
//==============================================================================

// --- Section Entity ---
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

// --- Énumérations pour les Blocs de Contenu ---
enum UploadStatus { uploading, completed, failed }

enum ContentBlockType { text, video, image, document, unknown }

// --- Entité pour un Bloc de Contenu ---
class ContentBlockEntity extends Equatable {
  final int id; // Vient de la BDD, 0 pour les nouveaux blocs
  final String localId; // ID unique temporaire généré dans l'UI
  final ContentBlockType blockType;
  final String content;
  final int orderIndex;
  final UploadStatus uploadStatus; // Statut du téléversement

  const ContentBlockEntity({
    required this.id,
    required this.localId,
    required this.blockType,
    required this.content,
    required this.orderIndex,
    this.uploadStatus = UploadStatus.completed,
  });

  // Factory pour créer un bloc depuis un JSON reçu de l'API.
  factory ContentBlockEntity.fromJson(Map<String, dynamic> json) {
    return ContentBlockEntity(
      id: json['id'],
      localId: json['id']
          .toString(), // On peut utiliser l'ID de la BDD comme ID local
      blockType: _blockTypeFromString(json['block_type']),
      content: json['content'],
      orderIndex: json['order_index'],
    );
  }

  // Méthode pour convertir l'entité en JSON avant de l'envoyer à l'API.
  Map<String, dynamic> toJson() {
    return {
      // On n'envoie pas l'ID car la BDD le gère (sauf si on voulait éditer)
      'block_type': blockType.name,
      'content': content,
      'order_index': orderIndex,
    };
  }

  ContentBlockEntity copyWith({
    int? id,
    String? localId,
    ContentBlockType? blockType,
    String? content,
    int? orderIndex,
    UploadStatus? uploadStatus,
  }) {
    return ContentBlockEntity(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      blockType: blockType ?? this.blockType,
      content: content ?? this.content,
      orderIndex: orderIndex ?? this.orderIndex,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  // Helper pour convertir une chaîne en ContentBlockType.
  static ContentBlockType _blockTypeFromString(String type) {
    return ContentBlockType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ContentBlockType.unknown,
    );
  }

  @override
  List<Object?> get props => [
    id,
    localId,
    blockType,
    content,
    orderIndex,
    uploadStatus,
  ];
}

// --- Énumération pour les types de leçons ---
enum LessonType { video, text, document, quiz, devoir, evaluation, unknown }

// --- Entité pour une Leçon ---
class LessonEntity extends Equatable {
  final int id;
  final String title;
  final LessonType lessonType;
  final List<ContentBlockEntity> contentBlocks;

  const LessonEntity({
    required this.id,
    required this.title,
    required this.lessonType,
    this.contentBlocks = const [],
  });

  factory LessonEntity.fromJson(Map<String, dynamic> json) {
    var blocks = <ContentBlockEntity>[];
    if (json['content_blocks'] != null) {
      blocks = (json['content_blocks'] as List)
          .map((blockJson) => ContentBlockEntity.fromJson(blockJson))
          .toList();
    }

    return LessonEntity(
      id: json['id'],
      title: json['title'],
      lessonType: _lessonTypeFromString(json['lesson_type']),
      contentBlocks: blocks,
    );
  }

  LessonEntity copyWith({
    int? id,
    String? title,
    LessonType? lessonType,
    List<ContentBlockEntity>? contentBlocks,
  }) {
    return LessonEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      lessonType: lessonType ?? this.lessonType,
      contentBlocks: contentBlocks ?? this.contentBlocks,
    );
  }

  static LessonType _lessonTypeFromString(String type) {
    return LessonType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => LessonType.unknown,
    );
  }

  @override
  List<Object?> get props => [id, title, lessonType, contentBlocks];
}

// --- Entité pour une Réponse ---
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

  Map<String, dynamic> toJson() {
    return {'answer_text': text, 'is_correct': isCorrect};
  }

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

// --- Entité pour une Question ---
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

  Map<String, dynamic> toJson() {
    return {
      'question_text': text,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }

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

// --- Entité pour un Quiz ---
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  QuizEntity copyWith({
    int? id,
    String? title,
    String? description,
    List<QuestionEntity>? questions,
  }) {
    return QuizEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
    );
  }

  @override
  List<Object?> get props => [id, title, description, questions];
}

//==============================================================================
// COURSE CONTENT BLOC
//==============================================================================

// --- Events ---
abstract class CourseContentEvent extends Equatable {
  const CourseContentEvent();
  @override
  List<Object> get props => [];
}

class FetchCourseContent extends CourseContentEvent {
  final String courseId;
  const FetchCourseContent(this.courseId);
}

// --- States ---
abstract class CourseContentState extends Equatable {
  const CourseContentState();
  @override
  List<Object> get props => [];
}

class CourseContentInitial extends CourseContentState {}

class CourseContentLoading extends CourseContentState {}

class CourseContentLoaded extends CourseContentState {
  final List<SectionEntity> sections;
  const CourseContentLoaded(this.sections);
}

class CourseContentError extends CourseContentState {
  final String message;
  const CourseContentError(this.message);
}

// --- Bloc ---
class CourseContentBloc extends Bloc<CourseContentEvent, CourseContentState> {
  final ApiClient apiClient;

  CourseContentBloc({required this.apiClient}) : super(CourseContentInitial()) {
    on<FetchCourseContent>(_onFetchCourseContent);
  }

  Future<void> _onFetchCourseContent(
    FetchCourseContent event,
    Emitter<CourseContentState> emit,
  ) async {
    emit(CourseContentLoading());
    try {
      final response = await apiClient.get(
        '/api/v1/get_course_content.php',
        queryParameters: {'course_id': event.courseId},
      );

      final List<SectionEntity> sections = (response.data as List).map((
        sectionData,
      ) {
        final List<LessonEntity> lessons = (sectionData['lessons'] as List).map(
          (lessonData) {
            return LessonEntity.fromJson(lessonData);
          },
        ).toList();

        return SectionEntity(
          id: sectionData['id'],
          title: sectionData['title'],
          lessons: lessons,
        );
      }).toList();

      emit(CourseContentLoaded(sections));
    } catch (e) {
      emit(CourseContentError(e.toString()));
    }
  }
}

//==============================================================================
// LESSON DETAIL BLOC
//==============================================================================

// --- Events ---
abstract class LessonDetailEvent extends Equatable {
  const LessonDetailEvent();
  @override
  List<Object> get props => [];
}

class FetchLessonDetails extends LessonDetailEvent {
  final int lessonId;
  const FetchLessonDetails(this.lessonId);
}

// --- States ---
abstract class LessonDetailState extends Equatable {
  const LessonDetailState();
  @override
  List<Object> get props => [];
}

class LessonDetailInitial extends LessonDetailState {}

class LessonDetailLoading extends LessonDetailState {}

class LessonDetailLoaded extends LessonDetailState {
  final LessonEntity lesson;
  const LessonDetailLoaded(this.lesson);
}

class LessonDetailError extends LessonDetailState {
  final String message;
  const LessonDetailError(this.message);
}

// --- Bloc ---
class LessonDetailBloc extends Bloc<LessonDetailEvent, LessonDetailState> {
  final ApiClient apiClient;

  LessonDetailBloc({required this.apiClient}) : super(LessonDetailInitial()) {
    on<FetchLessonDetails>((event, emit) async {
      emit(LessonDetailLoading());
      try {
        final response = await apiClient.get(
          '/api/v1/get_lesson_details.php',
          queryParameters: {'lesson_id': event.lessonId},
        );
        final lesson = LessonEntity.fromJson(response.data);
        emit(LessonDetailLoaded(lesson));
      } catch (e) {
        emit(LessonDetailError(e.toString()));
      }
    });
  }
}

//==============================================================================
// QUIZ BLOC
//==============================================================================

// --- Events ---
abstract class QuizEvent extends Equatable {
  const QuizEvent();
  @override
  List<Object> get props => [];
}

class FetchQuiz extends QuizEvent {
  final int lessonId;
  const FetchQuiz(this.lessonId);
}

class AnswerSelected extends QuizEvent {
  final int questionId;
  final int answerId;
  const AnswerSelected({required this.questionId, required this.answerId});
}

class SubmitQuiz extends QuizEvent {}

// --- States ---
enum QuizStatus { initial, loading, loaded, submitted, failure }

class QuizState extends Equatable {
  final QuizStatus status;
  final QuizEntity quiz;
  final Map<int, int> userAnswers;
  final double? score;
  final String error;

  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz = const QuizEntity(id: 0, title: '', questions: []),
    this.userAnswers = const {},
    this.score,
    this.error = '',
  });

  QuizState copyWith({
    QuizStatus? status,
    QuizEntity? quiz,
    Map<int, int>? userAnswers,
    double? score,
    String? error,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      userAnswers: userAnswers ?? this.userAnswers,
      score: score,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, quiz, userAnswers, score, error];
}

// --- Bloc ---
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final ApiClient apiClient;

  QuizBloc({required this.apiClient}) : super(const QuizState()) {
    on<FetchQuiz>(_onFetchQuiz);
    on<AnswerSelected>(_onAnswerSelected);
    on<SubmitQuiz>(_onSubmitQuiz);
  }

  Future<void> _onFetchQuiz(FetchQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(status: QuizStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_quiz_details.php',
        queryParameters: {'lesson_id': event.lessonId},
      );
      final quiz = QuizEntity.fromJson(response.data);
      emit(state.copyWith(status: QuizStatus.loaded, quiz: quiz));
    } catch (e) {
      emit(state.copyWith(status: QuizStatus.failure, error: e.toString()));
    }
  }

  void _onAnswerSelected(AnswerSelected event, Emitter<QuizState> emit) {
    final updatedAnswers = Map<int, int>.from(state.userAnswers);
    updatedAnswers[event.questionId] = event.answerId;
    emit(state.copyWith(userAnswers: updatedAnswers));
  }

  void _onSubmitQuiz(SubmitQuiz event, Emitter<QuizState> emit) {
    int correctAnswersCount = 0;
    for (var question in state.quiz.questions) {
      final correctAnswer = question.answers.firstWhere(
        (answer) => answer.isCorrect,
      );
      if (state.userAnswers[question.id] == correctAnswer.id) {
        correctAnswersCount++;
      }
    }
    final score = (correctAnswersCount / state.quiz.questions.length) * 100;
    emit(state.copyWith(status: QuizStatus.submitted, score: score));
  }
}
