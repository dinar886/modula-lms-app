// lib/features/course_player/course_player_logic.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';

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

// --- Lesson Entity ---
enum LessonType { video, text, document, quiz, unknown }

class LessonEntity extends Equatable {
  final int id;
  final String title;
  final LessonType lessonType;
  final String? contentUrl;
  final String? contentText;

  const LessonEntity({
    required this.id,
    required this.title,
    required this.lessonType,
    this.contentUrl,
    this.contentText,
  });

  factory LessonEntity.fromJson(Map<String, dynamic> json) {
    return LessonEntity(
      id: json['id'],
      title: json['title'],
      lessonType: LessonEntity.fromString(json['lesson_type']),
      contentUrl: json['content_url'],
      contentText: json['content_text'],
    );
  }

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
      contentUrl: contentUrl,
      contentText: contentText,
    );
  }

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

  @override
  List<Object?> get props => [id, title, lessonType, contentUrl, contentText];
}

// --- Answer Entity ---
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

// --- Question Entity ---
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

// --- Quiz Entity ---
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
            return LessonEntity(
              id: lessonData['id'],
              title: lessonData['title'],
              lessonType: LessonEntity.fromString(lessonData['lesson_type']),
            );
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
