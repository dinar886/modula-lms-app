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

// --- Entités SectionEntity, UploadStatus, ContentBlockType, ContentBlockEntity,
// --- LessonType, SubmissionEntity, LessonEntity, AnswerEntity, QuestionEntity,
// --- et QuizEntity sont INCHANGÉES.
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

  // ✅ CORRECTION APPLIQUÉE ICI
  factory SubmissionEntity.fromJson(Map<String, dynamic> json) {
    // Le champ 'content' arrive déjà décodé du PHP. On le traite directement comme une liste.
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

// --- NOUVELLE ENTITÉ ---
/// Représente les détails d'une tentative de quiz sauvegardée.
class QuizAttemptEntity extends Equatable {
  final int attemptId;
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime attemptDate;
  // Map<QuestionID, SelectedAnswerID>
  final Map<int, int> answers;

  const QuizAttemptEntity({
    required this.attemptId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.attemptDate,
    required this.answers,
  });

  factory QuizAttemptEntity.fromJson(Map<String, dynamic> json) {
    final answersMap = <int, int>{};
    if (json['answers'] != null) {
      for (var answerData in (json['answers'] as List)) {
        answersMap[answerData['question_id']] =
            answerData['selected_answer_id'];
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
// LESSON DETAIL BLOC (INCHANGÉ)
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
  final List<ContentBlockEntity> submissionContent; // Contenu du rendu

  const LessonDetailLoaded(this.lesson, {this.submissionContent = const []});

  @override
  List<Object> get props => [lesson, submissionContent];

  LessonDetailLoaded copyWith({
    LessonEntity? lesson,
    List<ContentBlockEntity>? submissionContent,
  }) {
    return LessonDetailLoaded(
      lesson ?? this.lesson,
      submissionContent: submissionContent ?? this.submissionContent,
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

// --- NOUVEL ÉVÉNEMENT ---
/// Événement pour recommencer le quiz.
class RestartQuiz extends QuizEvent {}

// --- ÉTAT MIS À JOUR ---
enum QuizStatus {
  initial,
  loading,
  loaded, // En train de répondre
  submitted, // A été soumis, en attente de la réponse du serveur
  showingResult, // Affiche le résultat d'une tentative précédente
  failure,
}

class QuizState extends Equatable {
  final QuizStatus status;
  final QuizEntity quiz;
  final Map<int, int> userAnswers; // Réponses de la tentative en cours
  final String error;
  final bool canAttemptQuiz;
  final QuizAttemptEntity? lastAttempt; // Détails de la dernière tentative

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
    Map<int, int>? userAnswers,
    String? error,
    bool? canAttemptQuiz,
    QuizAttemptEntity? lastAttempt,
    bool clearLastAttempt = false, // Pour effacer la dernière tentative
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
    on<SubmitQuiz>(_onSubmitQuiz);
    on<RestartQuiz>(_onRestartQuiz); // Enregistrement du nouvel événement
  }

  Future<void> _onFetchQuiz(FetchQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(status: QuizStatus.loading));
    try {
      // 1. Récupérer les détails de la leçon pour trouver le quizId et les métadonnées
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
        orElse: () => throw Exception("Aucun bloc de quiz trouvé."),
      );
      final quizId = int.parse(quizBlock.content);

      // 2. Récupérer le contenu du quiz
      final quizResponse = await apiClient.get(
        '/api/v1/get_quiz_details.php',
        queryParameters: {'quiz_id': quizId},
      );
      final quiz = QuizEntity.fromJson(quizResponse.data);

      // 3. Vérifier l'historique des tentatives
      final historyResponse = await apiClient.get(
        '/api/v1/get_quiz_history.php',
        queryParameters: {'student_id': event.studentId, 'quiz_id': quizId},
      );
      final attemptsCount = (historyResponse.data as List).length;
      final maxAttempts =
          (quizBlock.metadata['max_attempts'] as num?)?.toInt() ?? -1;

      bool canAttempt = (maxAttempts == -1 || attemptsCount < maxAttempts);
      if (maxAttempts == 0 && attemptsCount >= 1) {
        canAttempt = false;
      }

      // 4. Récupérer la dernière tentative détaillée
      final lastAttemptResponse = await apiClient.get(
        '/api/v1/get_last_quiz_attempt.php',
        queryParameters: {'student_id': event.studentId, 'quiz_id': quizId},
      );

      QuizAttemptEntity? lastAttempt;
      if (lastAttemptResponse.data != null) {
        lastAttempt = QuizAttemptEntity.fromJson(lastAttemptResponse.data);
      }

      // 5. Déterminer l'état initial
      if (lastAttempt != null) {
        // Si une tentative existe, on affiche les résultats directement
        emit(
          state.copyWith(
            status: QuizStatus.showingResult,
            quiz: quiz,
            lastAttempt: lastAttempt,
            canAttemptQuiz: canAttempt,
          ),
        );
      } else {
        // Sinon, on charge le quiz pour une nouvelle tentative
        emit(
          state.copyWith(
            status: QuizStatus.loaded,
            quiz: quiz,
            canAttemptQuiz: canAttempt,
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
    final updatedAnswers = Map<int, int>.from(state.userAnswers);
    updatedAnswers[event.questionId] = event.answerId;
    emit(state.copyWith(userAnswers: updatedAnswers));
  }

  Future<void> _onSubmitQuiz(SubmitQuiz event, Emitter<QuizState> emit) async {
    // On passe à `submitted` pour l'indicateur de chargement
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

      // Après la soumission, on refait un fetch complet pour obtenir le nouvel état
      add(FetchQuiz(lessonId: event.lessonId, studentId: event.studentId));
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
        clearLastAttempt: true, // On efface la tentative précédente de l'état
      ),
    );
  }
}
