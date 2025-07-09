// lib/features/course_player/course_player_logic.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart'; // Import nécessaire pour PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

//==============================================================================
// ENTITIES
//==============================================================================

// --- Les entités précédentes sont inchangées, seule QuizAttemptEntity change ---
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

enum ContentBlockType {
  text,
  video,
  image,
  document,
  quiz,
  submission_placeholder, // Le placeholder pour le rendu des élèves
  unknown,
}

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

    final int blockId = (json['id'] ?? 0) as int;
    final int orderIdx = (json['order_index'] ?? 0) as int;

    return ContentBlockEntity(
      id: blockId,
      localId: (json['localId'] ?? blockId.toString()) as String,
      blockType: _blockTypeFromString(json['block_type'] as String),
      content: json['content'] as String,
      orderIndex: orderIdx,
      metadata: metadataDecoded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localId': localId,
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

enum QuestionType { mcq, fill_in_the_blank }

class QuestionEntity extends Equatable {
  final int id;
  final String text;
  final QuestionType questionType;
  final String? correctTextAnswer;
  final List<AnswerEntity> answers;

  const QuestionEntity({
    required this.id,
    required this.text,
    required this.questionType,
    this.correctTextAnswer,
    required this.answers,
  });

  factory QuestionEntity.fromJson(Map<String, dynamic> json) {
    return QuestionEntity(
      id: json['id'],
      text: json['question_text'],
      questionType: _questionTypeFromString(json['question_type']),
      correctTextAnswer: json['correct_text_answer'],
      answers: (json['answers'] as List)
          .map((answerJson) => AnswerEntity.fromJson(answerJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id > 1000000000 ? 0 : id,
      'question_text': text,
      'question_type': questionType.name,
      'correct_text_answer': correctTextAnswer,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }

  QuestionEntity copyWith({
    int? id,
    String? text,
    QuestionType? questionType,
    String? correctTextAnswer,
    List<AnswerEntity>? answers,
  }) {
    return QuestionEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      questionType: questionType ?? this.questionType,
      correctTextAnswer: correctTextAnswer ?? this.correctTextAnswer,
      answers: answers ?? this.answers,
    );
  }

  static QuestionType _questionTypeFromString(String type) {
    return QuestionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => QuestionType.mcq,
    );
  }

  @override
  List<Object?> get props => [
    id,
    text,
    questionType,
    correctTextAnswer,
    answers,
  ];
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

class QuizAttemptEntity extends Equatable {
  final int attemptId;
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime attemptDate;
  // Map<QuestionID, dynamic> pour stocker soit l'ID (int) soit le texte (String)
  final Map<int, dynamic> answers;

  const QuizAttemptEntity({
    required this.attemptId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.attemptDate,
    required this.answers,
  });

  factory QuizAttemptEntity.fromJson(Map<String, dynamic> json) {
    final answersMap = <int, dynamic>{};
    if (json['answers'] != null) {
      for (var answerData in (json['answers'] as List)) {
        // Si `selected_text_answer` n'est pas null, on le stocke. Sinon, on stocke `selected_answer_id`.
        if (answerData['selected_text_answer'] != null) {
          answersMap[answerData['question_id']] =
              answerData['selected_text_answer'];
        } else {
          answersMap[answerData['question_id']] =
              answerData['selected_answer_id'];
        }
      }
    }
    return QuizAttemptEntity(
      attemptId: json['attempt_id'],
      score: (json['score'] as num).toDouble(),
      totalQuestions: json['total_questions'],
      correctAnswers: json['correct_answers'],
      attemptDate: DateTime.parse(json['attempt_date']),
      answers: answersMap,
    );
  }

  @override
  List<Object?> get props => [
    attemptId,
    score,
    totalQuestions,
    correctAnswers,
    attemptDate,
    answers,
  ];
}

//==============================================================================
// COURSE CONTENT BLOC (INCHANGÉ)
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
// LESSON DETAIL BLOC (MODIFIÉ)
//==============================================================================
abstract class LessonDetailEvent extends Equatable {
  const LessonDetailEvent();
  @override
  List<Object?> get props => [];
}

class FetchLessonDetails extends LessonDetailEvent {
  final int lessonId;
  final String studentId;
  const FetchLessonDetails({required this.lessonId, required this.studentId});
}

// NOUVEL ÉVÉNEMENT pour marquer un quiz comme terminé dans la leçon.
class QuizCompletedInLesson extends LessonDetailEvent {
  final int quizId;
  const QuizCompletedInLesson(this.quizId);
  @override
  List<Object?> get props => [quizId];
}

class SubmitAssignment extends LessonDetailEvent {
  final int lessonId;
  final int courseId;
  final String studentId;

  const SubmitAssignment({
    required this.lessonId,
    required this.courseId,
    required this.studentId,
  });
}

class UploadSubmissionFile extends LessonDetailEvent {
  final XFile file;
  const UploadSubmissionFile(this.file);
  @override
  List<Object?> get props => [file];
}

class RemoveSubmissionFile extends LessonDetailEvent {
  final String localBlockId;
  const RemoveSubmissionFile(this.localBlockId);
  @override
  List<Object?> get props => [localBlockId];
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
  final List<ContentBlockEntity> submissionContent;
  // NOUVEAU : On stocke les IDs des quiz terminés.
  final Set<int> completedQuizIds;

  const LessonDetailLoaded(
    this.lesson, {
    this.submissionContent = const [],
    this.completedQuizIds = const {},
  });

  @override
  List<Object> get props => [lesson, submissionContent, completedQuizIds];

  LessonDetailLoaded copyWith({
    LessonEntity? lesson,
    List<ContentBlockEntity>? submissionContent,
    Set<int>? completedQuizIds,
  }) {
    return LessonDetailLoaded(
      lesson ?? this.lesson,
      submissionContent: submissionContent ?? this.submissionContent,
      completedQuizIds: completedQuizIds ?? this.completedQuizIds,
    );
  }
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
    on<QuizCompletedInLesson>(_onQuizCompletedInLesson);
    on<SubmitAssignment>(_onSubmitAssignment);
    on<UploadSubmissionFile>(_onUploadSubmissionFile);
    on<RemoveSubmissionFile>(_onRemoveSubmissionFile);
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

      final initialSubmissionContent = lesson.submission?.content ?? [];

      emit(
        LessonDetailLoaded(lesson, submissionContent: initialSubmissionContent),
      );
    } catch (e) {
      emit(
        LessonDetailError(
          "Erreur lors de la récupération des détails de la leçon : ${e.toString()}",
        ),
      );
    }
  }

  // NOUVEAU HANDLER : Met à jour l'état quand un quiz est terminé.
  void _onQuizCompletedInLesson(
    QuizCompletedInLesson event,
    Emitter<LessonDetailState> emit,
  ) {
    if (state is! LessonDetailLoaded) return;
    final loadedState = state as LessonDetailLoaded;

    // On crée une nouvelle copie du Set pour garantir l'immutabilité.
    final updatedQuizIds = Set<int>.from(loadedState.completedQuizIds);
    updatedQuizIds.add(event.quizId);

    emit(loadedState.copyWith(completedQuizIds: updatedQuizIds));
  }

  Future<void> _onSubmitAssignment(
    SubmitAssignment event,
    Emitter<LessonDetailState> emit,
  ) async {
    if (state is! LessonDetailLoaded) return;
    final loadedState = state as LessonDetailLoaded;

    emit(LessonDetailSubmitting());
    try {
      final data = {
        'lesson_id': event.lessonId,
        'course_id': event.courseId,
        'student_id': event.studentId,
        'content': loadedState.submissionContent
            .map((block) => block.toJson())
            .toList(),
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
      add(
        FetchLessonDetails(
          lessonId: event.lessonId,
          studentId: event.studentId,
        ),
      );
    }
  }

  Future<void> _onUploadSubmissionFile(
    UploadSubmissionFile event,
    Emitter<LessonDetailState> emit,
  ) async {
    if (state is! LessonDetailLoaded) return;
    final currentState = state as LessonDetailLoaded;
    final localId = DateTime.now().millisecondsSinceEpoch.toString();

    final tempBlock = ContentBlockEntity(
      id: 0,
      localId: localId,
      blockType: ContentBlockType.document,
      content: event.file.name,
      orderIndex: currentState.submissionContent.length,
      uploadStatus: UploadStatus.uploading,
      metadata: {'fileName': event.file.name},
    );

    final listWithTempBlock = List<ContentBlockEntity>.from(
      currentState.submissionContent,
    )..add(tempBlock);

    emit(currentState.copyWith(submissionContent: listWithTempBlock));

    try {
      final response = await apiClient.postMultipart(
        path: '/api/v1/upload_file.php',
        data: {},
        file: event.file,
      );
      final fileUrl = response.data['url'];

      final finalBlock = tempBlock.copyWith(
        content: fileUrl,
        uploadStatus: UploadStatus.completed,
      );

      final latestState = state as LessonDetailLoaded;
      final listToUpdate = List<ContentBlockEntity>.from(
        latestState.submissionContent,
      );
      final index = listToUpdate.indexWhere((b) => b.localId == localId);

      if (index != -1) {
        listToUpdate[index] = finalBlock;
      }

      emit(latestState.copyWith(submissionContent: listToUpdate));
    } catch (e) {
      final failedBlock = tempBlock.copyWith(uploadStatus: UploadStatus.failed);

      final latestState = state as LessonDetailLoaded;
      final listToUpdate = List<ContentBlockEntity>.from(
        latestState.submissionContent,
      );
      final index = listToUpdate.indexWhere((b) => b.localId == localId);

      if (index != -1) {
        listToUpdate[index] = failedBlock;
      }

      emit(latestState.copyWith(submissionContent: listToUpdate));
    }
  }

  void _onRemoveSubmissionFile(
    RemoveSubmissionFile event,
    Emitter<LessonDetailState> emit,
  ) {
    if (state is! LessonDetailLoaded) return;
    final loadedState = state as LessonDetailLoaded;

    final updatedContent = loadedState.submissionContent
        .where((b) => b.localId != event.localBlockId)
        .toList();

    emit(loadedState.copyWith(submissionContent: updatedContent));
  }
}

//==============================================================================
// QUIZ BLOC (MODIFIÉ)
//==============================================================================

abstract class QuizEvent extends Equatable {
  const QuizEvent();
  @override
  List<Object> get props => [];
}

class FetchQuiz extends QuizEvent {
  final int quizId;
  final String studentId;
  final int maxAttempts;
  const FetchQuiz({
    required this.quizId,
    required this.studentId,
    required this.maxAttempts,
  });
}

class AnswerSelected extends QuizEvent {
  final int questionId;
  final int answerId;
  const AnswerSelected({required this.questionId, required this.answerId});
}

// NOUVEL ÉVÉNEMENT pour les réponses textuelles
class TextAnswerChanged extends QuizEvent {
  final int questionId;
  final String text;
  const TextAnswerChanged({required this.questionId, required this.text});
}

class SubmitQuiz extends QuizEvent {
  final String studentId;
  final int lessonId; // On garde lessonId pour la table quiz_attempts
  const SubmitQuiz({required this.studentId, required this.lessonId});
}

class RestartQuiz extends QuizEvent {}

enum QuizStatus { initial, loading, loaded, submitted, showingResult, failure }

class QuizState extends Equatable {
  final QuizStatus status;
  final QuizEntity quiz;
  // Les réponses peuvent être des int (ID de QCM) ou des String (texte à trous)
  final Map<int, dynamic> userAnswers;
  final String error;
  final bool canAttemptQuiz;
  final QuizAttemptEntity? lastAttempt;

  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz = const QuizEntity(id: 0, title: '', questions: []),
    this.userAnswers = const {},
    this.error = '',
    this.canAttemptQuiz = true,
    this.lastAttempt,
  });

  QuizState copyWith({
    QuizStatus? status,
    QuizEntity? quiz,
    Map<int, dynamic>? userAnswers,
    String? error,
    bool? canAttemptQuiz,
    QuizAttemptEntity? lastAttempt,
    bool clearLastAttempt = false,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      userAnswers: userAnswers ?? this.userAnswers,
      error: error ?? this.error,
      canAttemptQuiz: canAttemptQuiz ?? this.canAttemptQuiz,
      lastAttempt: clearLastAttempt ? null : lastAttempt ?? this.lastAttempt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    quiz,
    userAnswers,
    error,
    canAttemptQuiz,
    lastAttempt,
  ];
}

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final ApiClient apiClient;

  QuizBloc({required this.apiClient}) : super(const QuizState()) {
    on<FetchQuiz>(_onFetchQuiz);
    on<AnswerSelected>(_onAnswerSelected);
    on<TextAnswerChanged>(_onTextAnswerChanged); // Nouvel handler
    on<SubmitQuiz>(_onSubmitQuiz);
    on<RestartQuiz>(_onRestartQuiz);
  }

  Future<void> _onFetchQuiz(FetchQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(status: QuizStatus.loading));
    try {
      // 1. Récupérer le contenu du quiz directement avec son ID
      final quizResponse = await apiClient.get(
        '/api/v1/get_quiz_details.php',
        queryParameters: {'quiz_id': event.quizId},
      );
      final quiz = QuizEntity.fromJson(quizResponse.data);

      // 2. Vérifier l'historique des tentatives
      final historyResponse = await apiClient.get(
        '/api/v1/get_quiz_history.php',
        queryParameters: {
          'student_id': event.studentId,
          'quiz_id': event.quizId,
        },
      );
      final attemptsCount = (historyResponse.data as List).length;

      // Utilise le nombre de tentatives max passé en paramètre
      bool canAttempt =
          (event.maxAttempts == -1 || attemptsCount < event.maxAttempts);
      if (event.maxAttempts == 0 && attemptsCount >= 1) {
        canAttempt = false;
      }

      // 3. Récupérer la dernière tentative détaillée
      final lastAttemptResponse = await apiClient.get(
        '/api/v1/get_last_quiz_attempt.php',
        queryParameters: {
          'student_id': event.studentId,
          'quiz_id': event.quizId,
        },
      );

      QuizAttemptEntity? lastAttempt;
      if (lastAttemptResponse.data != null) {
        lastAttempt = QuizAttemptEntity.fromJson(lastAttemptResponse.data);
      }

      // 4. Déterminer l'état initial
      if (lastAttempt != null) {
        emit(
          state.copyWith(
            status: QuizStatus.showingResult,
            quiz: quiz,
            lastAttempt: lastAttempt,
            canAttemptQuiz: canAttempt,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: QuizStatus.loaded,
            quiz: quiz,
            canAttemptQuiz: canAttempt,
            userAnswers: {}, // On s'assure de vider les réponses précédentes
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          error: "Erreur chargement quiz : ${e.toString()}",
        ),
      );
    }
  }

  void _onAnswerSelected(AnswerSelected event, Emitter<QuizState> emit) {
    final updatedAnswers = Map<int, dynamic>.from(state.userAnswers);
    updatedAnswers[event.questionId] = event.answerId;
    emit(state.copyWith(userAnswers: updatedAnswers));
  }

  void _onTextAnswerChanged(TextAnswerChanged event, Emitter<QuizState> emit) {
    final updatedAnswers = Map<int, dynamic>.from(state.userAnswers);
    updatedAnswers[event.questionId] = event.text;
    emit(state.copyWith(userAnswers: updatedAnswers));
  }

  Future<void> _onSubmitQuiz(SubmitQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(status: QuizStatus.submitted));
    try {
      final answersWithStringKeys = state.userAnswers.map((key, value) {
        return MapEntry(key.toString(), value);
      });

      await apiClient.post(
        '/api/v1/submit_quiz.php',
        data: {
          'student_id': event.studentId,
          'quiz_id': state.quiz.id,
          'lesson_id': event.lessonId,
          'answers': answersWithStringKeys,
        },
      );

      // On refait un fetch pour obtenir le nouvel état complet avec les résultats
      add(
        FetchQuiz(
          quizId: state.quiz.id,
          studentId: event.studentId,
          maxAttempts: -1, // La valeur ici n'est pas critique après soumission
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          error: "Erreur soumission quiz : ${e.toString()}",
        ),
      );
    }
  }

  void _onRestartQuiz(RestartQuiz event, Emitter<QuizState> emit) {
    emit(
      state.copyWith(
        status: QuizStatus.loaded,
        userAnswers: {},
        clearLastAttempt: true,
      ),
    );
  }
}
