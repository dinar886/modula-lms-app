// lib/features/course_player/course_player_logic.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart'; // Import nécessaire pour PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

//==============================================================================
// ENTITIES
//==============================================================================

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

enum UploadStatus { uploading, completed, failed }

enum ContentBlockType { text, video, image, document, quiz, unknown }

class ContentBlockEntity extends Equatable {
  final int id;
  final String localId;
  final ContentBlockType blockType;
  final String content;
  final int orderIndex;
  final UploadStatus uploadStatus;
  final Map<String, dynamic> metadata;

  const ContentBlockEntity({
    required this.id,
    required this.localId,
    required this.blockType,
    required this.content,
    required this.orderIndex,
    this.uploadStatus = UploadStatus.completed,
    this.metadata = const {},
  });

  factory ContentBlockEntity.fromJson(Map<String, dynamic> json) {
    final metadataRaw = json['metadata'];
    Map<String, dynamic> metadataDecoded = {};
    if (metadataRaw is String && metadataRaw.isNotEmpty) {
      try {
        metadataDecoded = jsonDecode(metadataRaw);
      } catch (e) {
        print('Erreur de décodage JSON pour les métadonnées: $e');
      }
    } else if (metadataRaw is Map) {
      metadataDecoded = Map<String, dynamic>.from(metadataRaw);
    }

    return ContentBlockEntity(
      id: json['id'] as int,
      localId: (json['id'] as int).toString(),
      blockType: _blockTypeFromString(json['block_type'] as String),
      content: json['content'] as String,
      orderIndex: json['order_index'] as int,
      metadata: metadataDecoded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'block_type': blockType.name,
      'content': content,
      'order_index': orderIndex,
      'metadata': jsonEncode(metadata),
    };
  }

  ContentBlockEntity copyWith({
    int? id,
    String? localId,
    ContentBlockType? blockType,
    String? content,
    int? orderIndex,
    UploadStatus? uploadStatus,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlockEntity(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      blockType: blockType ?? this.blockType,
      content: content ?? this.content,
      orderIndex: orderIndex ?? this.orderIndex,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      metadata: metadata ?? this.metadata,
    );
  }

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
    metadata,
  ];
}

enum LessonType { text, video, document, quiz, devoir, evaluation, unknown }

class SubmissionEntity extends Equatable {
  final int id;
  final DateTime submissionDate;
  final List<ContentBlockEntity> content; // Le contenu est une liste de blocs
  final double? grade;
  final String status;
  final String? instructorFeedback;

  const SubmissionEntity({
    required this.id,
    required this.submissionDate,
    required this.content,
    this.grade,
    required this.status,
    this.instructorFeedback,
  });

  factory SubmissionEntity.fromJson(Map<String, dynamic> json) {
    return SubmissionEntity(
      id: json['id'],
      submissionDate: DateTime.parse(json['submission_date']),
      content: (json['content'] as List)
          .map((blockJson) => ContentBlockEntity.fromJson(blockJson))
          .toList(),
      grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
      status: json['status'],
      instructorFeedback: json['instructor_feedback'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    submissionDate,
    content,
    grade,
    status,
    instructorFeedback,
  ];
}

class LessonEntity extends Equatable {
  final int id;
  final String title;
  final LessonType lessonType;
  final DateTime? dueDate;
  final List<ContentBlockEntity> contentBlocks;
  final SubmissionEntity? submission;
  final Map<String, dynamic> metadata;

  const LessonEntity({
    required this.id,
    required this.title,
    required this.lessonType,
    this.dueDate,
    this.contentBlocks = const [],
    this.submission,
    this.metadata = const {},
  });

  factory LessonEntity.fromJson(Map<String, dynamic> json) {
    var blocks = <ContentBlockEntity>[];
    if (json['content_blocks'] != null) {
      blocks = (json['content_blocks'] as List)
          .map((blockJson) => ContentBlockEntity.fromJson(blockJson))
          .toList();
    }

    final metadataRaw = json['metadata'];
    Map<String, dynamic> metadataDecoded = {};
    if (metadataRaw is String && metadataRaw.isNotEmpty) {
      try {
        metadataDecoded = jsonDecode(metadataRaw);
      } catch (e) {
        print('Erreur décodage JSON pour métadonnées de leçon: $e');
      }
    } else if (metadataRaw is Map) {
      metadataDecoded = Map<String, dynamic>.from(metadataRaw);
    }

    return LessonEntity(
      id: json['id'],
      title: json['title'],
      // L'appel ici utilise la méthode qui a été renommée.
      lessonType: lessonTypeFromString(json['lesson_type']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      contentBlocks: blocks,
      submission: json['submission'] != null
          ? SubmissionEntity.fromJson(json['submission'])
          : null,
      metadata: metadataDecoded,
    );
  }

  LessonEntity copyWith({
    int? id,
    String? title,
    LessonType? lessonType,
    DateTime? dueDate,
    List<ContentBlockEntity>? contentBlocks,
    SubmissionEntity? submission,
    Map<String, dynamic>? metadata,
  }) {
    return LessonEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      lessonType: lessonType ?? this.lessonType,
      dueDate: dueDate ?? this.dueDate,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      submission: submission ?? this.submission,
      metadata: metadata ?? this.metadata,
    );
  }

  // ✅ CORRECTION APPLIQUÉE ICI
  // La méthode est maintenant statique et publique (plus de `_` au début).
  // Elle peut donc être appelée depuis n'importe quel autre fichier, comme `LessonEntity.lessonTypeFromString(...)`.
  static LessonType lessonTypeFromString(String type) {
    return LessonType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => LessonType.unknown,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    lessonType,
    dueDate,
    contentBlocks,
    submission,
    metadata,
  ];
}

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
      isCorrect: json['is_correct'] == 1 || json['is_correct'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id > 1000000000 ? 0 : id,
      'answer_text': text,
      'is_correct': isCorrect,
    };
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
      'id': id > 1000000000 ? 0 : id,
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
abstract class CourseContentEvent extends Equatable {
  const CourseContentEvent();
  @override
  List<Object> get props => [];
}

class FetchCourseContent extends CourseContentEvent {
  final String courseId;
  const FetchCourseContent(this.courseId);
}

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
      emit(
        CourseContentError(
          "Erreur lors de la récupération du contenu du cours : ${e.toString()}",
        ),
      );
    }
  }
}

//==============================================================================
// LESSON DETAIL BLOC
//==============================================================================
abstract class LessonDetailEvent extends Equatable {
  const LessonDetailEvent();
  @override
  List<Object> get props => [];
}

class FetchLessonDetails extends LessonDetailEvent {
  final int lessonId;
  final String studentId;
  const FetchLessonDetails({required this.lessonId, required this.studentId});
}

class SubmitAssignment extends LessonDetailEvent {
  final int lessonId;
  final int courseId;
  final String studentId;
  final List<ContentBlockEntity> content;

  const SubmitAssignment({
    required this.lessonId,
    required this.courseId,
    required this.studentId,
    required this.content,
  });
}

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

class LessonDetailSubmitting extends LessonDetailState {}

class LessonDetailSubmitSuccess extends LessonDetailState {}

class LessonDetailBloc extends Bloc<LessonDetailEvent, LessonDetailState> {
  final ApiClient apiClient;

  LessonDetailBloc({required this.apiClient}) : super(LessonDetailInitial()) {
    on<FetchLessonDetails>(_onFetchLessonDetails);
    on<SubmitAssignment>(_onSubmitAssignment);
  }

  Future<void> _onFetchLessonDetails(
    FetchLessonDetails event,
    Emitter<LessonDetailState> emit,
  ) async {
    emit(LessonDetailLoading());
    try {
      final response = await apiClient.get(
        '/api/v1/get_lesson_details.php',
        queryParameters: {
          'lesson_id': event.lessonId,
          'student_id': event.studentId,
        },
      );
      final lesson = LessonEntity.fromJson(response.data);
      emit(LessonDetailLoaded(lesson));
    } catch (e) {
      emit(
        LessonDetailError(
          "Erreur lors de la récupération des détails de la leçon : ${e.toString()}",
        ),
      );
    }
  }

  Future<void> _onSubmitAssignment(
    SubmitAssignment event,
    Emitter<LessonDetailState> emit,
  ) async {
    emit(LessonDetailSubmitting());
    try {
      final data = {
        'lesson_id': event.lessonId,
        'course_id': event.courseId,
        'student_id': event.studentId,
        'content': event.content.map((block) => block.toJson()).toList(),
      };
      await apiClient.post('/api/v1/submit_assignment.php', data: data);
      emit(LessonDetailSubmitSuccess());
      add(
        FetchLessonDetails(
          lessonId: event.lessonId,
          studentId: event.studentId,
        ),
      );
    } catch (e) {
      emit(LessonDetailError("Erreur lors de la soumission : ${e.toString()}"));
    }
  }
}

//==============================================================================
// QUIZ BLOC
//==============================================================================

abstract class QuizEvent extends Equatable {
  const QuizEvent();
  @override
  List<Object> get props => [];
}

class FetchQuiz extends QuizEvent {
  final int lessonId;
  final String studentId;
  const FetchQuiz({required this.lessonId, required this.studentId});
}

class AnswerSelected extends QuizEvent {
  final int questionId;
  final int answerId;
  const AnswerSelected({required this.questionId, required this.answerId});
}

class SubmitQuiz extends QuizEvent {
  final String studentId;
  final int lessonId;
  const SubmitQuiz({required this.studentId, required this.lessonId});
}

enum QuizStatus { initial, loading, loaded, submitted, failure }

class QuizState extends Equatable {
  final QuizStatus status;
  final QuizEntity quiz;
  final Map<int, int> userAnswers;
  final double? score;
  final String error;
  final bool canAttemptQuiz;

  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz = const QuizEntity(id: 0, title: '', questions: []),
    this.userAnswers = const {},
    this.score,
    this.error = '',
    this.canAttemptQuiz = true,
  });

  QuizState copyWith({
    QuizStatus? status,
    QuizEntity? quiz,
    Map<int, int>? userAnswers,
    double? score,
    String? error,
    bool? canAttemptQuiz,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      userAnswers: userAnswers ?? this.userAnswers,
      score: score,
      error: error ?? this.error,
      canAttemptQuiz: canAttemptQuiz ?? this.canAttemptQuiz,
    );
  }

  @override
  List<Object?> get props => [
    status,
    quiz,
    userAnswers,
    score,
    error,
    canAttemptQuiz,
  ];
}

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
      final lessonResponse = await apiClient.get(
        '/api/v1/get_lesson_details.php',
        queryParameters: {
          'lesson_id': event.lessonId,
          'student_id': event.studentId,
        },
      );
      final lesson = LessonEntity.fromJson(lessonResponse.data);
      final quizBlock = lesson.contentBlocks.firstWhere(
        (b) => b.blockType == ContentBlockType.quiz,
        orElse: () =>
            throw Exception("Aucun bloc de type quiz trouvé dans cette leçon."),
      );
      final quizId = int.parse(quizBlock.content);
      final maxAttempts =
          (quizBlock.metadata['max_attempts'] as num?)?.toInt() ?? -1;

      final historyResponse = await apiClient.get(
        '/api/v1/get_quiz_history.php',
        queryParameters: {'student_id': event.studentId, 'quiz_id': quizId},
      );
      final attempts = (historyResponse.data as List);
      final attemptsCount = attempts.length;

      bool canAttempt = true;
      if (maxAttempts == 0) {
        if (attemptsCount >= 1) {
          canAttempt = false;
        }
      } else if (maxAttempts != -1 && attemptsCount >= maxAttempts) {
        canAttempt = false;
      }

      final quizResponse = await apiClient.get(
        '/api/v1/get_quiz_details.php',
        queryParameters: {'quiz_id': quizId},
      );
      final quiz = QuizEntity.fromJson(quizResponse.data);

      emit(
        state.copyWith(
          status: QuizStatus.loaded,
          quiz: quiz,
          canAttemptQuiz: canAttempt,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          error: "Erreur lors du chargement du quiz : ${e.toString()}",
        ),
      );
    }
  }

  void _onAnswerSelected(AnswerSelected event, Emitter<QuizState> emit) {
    final updatedAnswers = Map<int, int>.from(state.userAnswers);
    updatedAnswers[event.questionId] = event.answerId;
    emit(state.copyWith(userAnswers: updatedAnswers));
  }

  Future<void> _onSubmitQuiz(SubmitQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(status: QuizStatus.loading));
    try {
      final answersWithStringKeys = state.userAnswers.map((key, value) {
        return MapEntry(key.toString(), value);
      });

      final response = await apiClient.post(
        '/api/v1/submit_quiz.php',
        data: {
          'student_id': event.studentId,
          'quiz_id': state.quiz.id,
          'lesson_id': event.lessonId,
          'answers': answersWithStringKeys,
        },
      );

      final score = (response.data['score'] as num).toDouble();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('quiz_completed_${event.lessonId}', true);
      } on PlatformException catch (e) {
        print(
          "AVERTISSEMENT: Échec de la sauvegarde locale du statut du quiz (PlatformException): $e",
        );
      } catch (e) {
        print(
          "AVERTISSEMENT: Échec de la sauvegarde locale du statut du quiz (Erreur inconnue): $e",
        );
      }

      emit(
        state.copyWith(
          status: QuizStatus.submitted,
          score: score,
          canAttemptQuiz: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          error: "Erreur lors de la soumission du quiz : ${e.toString()}",
        ),
      );
    }
  }
}
