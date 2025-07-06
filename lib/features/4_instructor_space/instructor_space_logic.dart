// lib/features/4_instructor_space/instructor_space_logic.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';

//==============================================================================
// COURSE MANAGEMENT (Création de cours)
//==============================================================================

// --- EVENTS ---

abstract class CourseManagementEvent extends Equatable {
  const CourseManagementEvent();
  @override
  List<Object?> get props => [];
}

class CreateCourseRequested extends CourseManagementEvent {
  final String title;
  final String description;
  final double price;
  final String instructorId;
  final XFile? imageFile;
  final Color? color;

  const CreateCourseRequested({
    required this.title,
    required this.description,
    required this.price,
    required this.instructorId,
    this.imageFile,
    this.color,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    price,
    instructorId,
    imageFile,
    color,
  ];
}

// --- STATES ---

enum CourseManagementStatus { initial, loading, success, failure }

class CourseManagementState extends Equatable {
  final CourseManagementStatus status;
  final String error;

  const CourseManagementState({
    this.status = CourseManagementStatus.initial,
    this.error = '',
  });

  CourseManagementState copyWith({
    CourseManagementStatus? status,
    String? error,
  }) {
    return CourseManagementState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props => [status, error];
}

// --- BLOC ---

class CourseManagementBloc
    extends Bloc<CourseManagementEvent, CourseManagementState> {
  final ApiClient apiClient;

  CourseManagementBloc({required this.apiClient})
    : super(const CourseManagementState()) {
    on<CreateCourseRequested>(_onCreateCourseRequested);
  }

  Future<void> _onCreateCourseRequested(
    CreateCourseRequested event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(state.copyWith(status: CourseManagementStatus.loading));
    try {
      final data = {
        'title': event.title,
        'description': event.description,
        'price': event.price.toString(),
        'instructor_id': event.instructorId,
        if (event.color != null)
          'color':
              '#${event.color!.value.toRadixString(16).substring(2).toUpperCase()}',
      };

      // **CORRECTION APPLIQUÉE ICI**
      // Utilisation du paramètre nommé `path:` pour l'URL.
      await apiClient.postMultipart(
        path: '/api/v1/create_course.php',
        data: data,
        imageFile: event.imageFile,
      );

      emit(state.copyWith(status: CourseManagementStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseManagementStatus.failure,
          error: "Erreur lors de la création : ${e.toString()}",
        ),
      );
    }
  }
}

//==============================================================================
// COURSE EDITOR (Sections & Leçons)
//==============================================================================

// --- EVENTS ---
abstract class CourseEditorEvent extends Equatable {
  const CourseEditorEvent();
  @override
  List<Object> get props => [];
}

class AddSection extends CourseEditorEvent {
  final String title;
  final String courseId;
  const AddSection({required this.title, required this.courseId});
}

class AddLesson extends CourseEditorEvent {
  final String title;
  final int sectionId;
  final String lessonType;
  const AddLesson({
    required this.title,
    required this.sectionId,
    required this.lessonType,
  });
}

class EditSection extends CourseEditorEvent {
  final String newTitle;
  final int sectionId;
  const EditSection({required this.newTitle, required this.sectionId});
}

class EditLesson extends CourseEditorEvent {
  final String newTitle;
  final int lessonId;
  const EditLesson({required this.newTitle, required this.lessonId});
}

class DeleteSection extends CourseEditorEvent {
  final int sectionId;
  const DeleteSection(this.sectionId);
}

class DeleteLesson extends CourseEditorEvent {
  final int lessonId;
  const DeleteLesson(this.lessonId);
}

// --- STATES ---
abstract class CourseEditorState extends Equatable {
  const CourseEditorState();
  @override
  List<Object> get props => [];
}

class CourseEditorInitial extends CourseEditorState {}

class CourseEditorLoading extends CourseEditorState {}

class CourseEditorSuccess extends CourseEditorState {}

class CourseEditorFailure extends CourseEditorState {
  final String error;
  const CourseEditorFailure(this.error);
}

// --- BLOC ---
class CourseEditorBloc extends Bloc<CourseEditorEvent, CourseEditorState> {
  final ApiClient apiClient;

  CourseEditorBloc({required this.apiClient}) : super(CourseEditorInitial()) {
    on<AddSection>(_onAddSection);
    on<AddLesson>(_onAddLesson);
    on<EditSection>(_onEditSection);
    on<DeleteSection>(_onDeleteSection);
    on<EditLesson>(_onEditLesson);
    on<DeleteLesson>(_onDeleteLesson);
  }

  Future<void> _onAddSection(
    AddSection event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/add_section.php',
        data: {'title': event.title, 'course_id': event.courseId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onAddLesson(
    AddLesson event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/add_lesson.php',
        data: {
          'title': event.title,
          'section_id': event.sectionId,
          'lesson_type': event.lessonType,
        },
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onEditSection(
    EditSection event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/edit_section.php',
        data: {'title': event.newTitle, 'section_id': event.sectionId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onDeleteSection(
    DeleteSection event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/delete_section.php',
        data: {'section_id': event.sectionId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onEditLesson(
    EditLesson event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/edit_lesson.php',
        data: {'title': event.newTitle, 'lesson_id': event.lessonId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }

  Future<void> _onDeleteLesson(
    DeleteLesson event,
    Emitter<CourseEditorState> emit,
  ) async {
    emit(CourseEditorLoading());
    try {
      await apiClient.post(
        '/api/v1/delete_lesson.php',
        data: {'lesson_id': event.lessonId},
      );
      emit(CourseEditorSuccess());
    } catch (e) {
      emit(CourseEditorFailure(e.toString()));
    }
  }
}

//==============================================================================
// COURSE INFO EDITOR (Titre, description, prix, image)
//==============================================================================

// --- EVENTS ---
abstract class CourseInfoEditorEvent extends Equatable {
  const CourseInfoEditorEvent();
  @override
  List<Object?> get props => [];
}

class LoadCourseInfo extends CourseInfoEditorEvent {
  final String courseId;
  const LoadCourseInfo(this.courseId);
}

class CourseInfoChanged extends CourseInfoEditorEvent {
  final String? title;
  final String? description;
  final double? price;
  final XFile? newImageFile;
  final Color? newColor;
  final bool clearImage;

  const CourseInfoChanged({
    this.title,
    this.description,
    this.price,
    this.newImageFile,
    this.newColor,
    this.clearImage = false,
  });
}

class RemoveCourseImage extends CourseInfoEditorEvent {}

class SaveCourseInfoChanges extends CourseInfoEditorEvent {}

// --- STATES ---
enum CourseInfoEditorStatus {
  initial,
  loading,
  loaded,
  saving,
  success,
  failure,
}

class CourseInfoEditorState extends Equatable {
  final CourseInfoEditorStatus status;
  final CourseEntity course;
  final String error;
  final bool isDirty;
  final XFile? newImageFile;
  final Color? newColor;

  const CourseInfoEditorState({
    this.status = CourseInfoEditorStatus.initial,
    this.course = const CourseEntity(
      id: '',
      title: '',
      author: '',
      imageUrl: '',
      price: 0,
    ),
    this.error = '',
    this.isDirty = false,
    this.newImageFile,
    this.newColor,
  });

  CourseInfoEditorState copyWith({
    CourseInfoEditorStatus? status,
    CourseEntity? course,
    String? error,
    bool? isDirty,
    XFile? newImageFile,
    Color? newColor,
    bool clearImage = false,
  }) {
    return CourseInfoEditorState(
      status: status ?? this.status,
      course: course ?? this.course,
      error: error ?? this.error,
      isDirty: isDirty ?? this.isDirty,
      newImageFile: clearImage ? null : newImageFile ?? this.newImageFile,
      newColor: newColor ?? this.newColor,
    );
  }

  @override
  List<Object?> get props => [
    status,
    course,
    error,
    isDirty,
    newImageFile,
    newColor,
  ];
}

// --- BLOC ---

class CourseInfoEditorBloc
    extends Bloc<CourseInfoEditorEvent, CourseInfoEditorState> {
  final ApiClient apiClient;

  CourseInfoEditorBloc({required this.apiClient})
    : super(const CourseInfoEditorState()) {
    on<LoadCourseInfo>(_onLoadCourseInfo);
    on<CourseInfoChanged>(_onCourseInfoChanged);
    on<RemoveCourseImage>(_onRemoveCourseImage);
    on<SaveCourseInfoChanges>(_onSaveCourseInfoChanges);
  }

  Future<void> _onLoadCourseInfo(
    LoadCourseInfo event,
    Emitter<CourseInfoEditorState> emit,
  ) async {
    emit(state.copyWith(status: CourseInfoEditorStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_course_details.php',
        queryParameters: {'id': event.courseId},
      );
      final course = CourseEntity.fromJson(response.data);
      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.loaded,
          course: course,
          isDirty: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void _onCourseInfoChanged(
    CourseInfoChanged event,
    Emitter<CourseInfoEditorState> emit,
  ) {
    final newCourse = state.course.copyWith(
      title: event.title,
      description: event.description,
      price: event.price,
    );
    emit(
      state.copyWith(
        course: newCourse,
        newImageFile: event.newImageFile,
        newColor: event.newColor,
        isDirty: true,
        clearImage: event.clearImage,
      ),
    );
  }

  void _onRemoveCourseImage(
    RemoveCourseImage event,
    Emitter<CourseInfoEditorState> emit,
  ) {
    final title = state.course.title;
    final color = state.newColor ?? const Color(0xFF005A9C);
    final hexColor = color.value.toRadixString(16).substring(2).toUpperCase();
    final encodedTitle = Uri.encodeComponent(title);
    final placeholderUrl =
        "https://placehold.co/600x400/$hexColor/FFFFFF/png?text=$encodedTitle";

    final updatedCourse = state.course.copyWith(imageUrl: placeholderUrl);

    emit(
      state.copyWith(
        course: updatedCourse,
        newImageFile: null,
        clearImage: true,
        isDirty: true,
      ),
    );
  }

  Future<void> _onSaveCourseInfoChanges(
    SaveCourseInfoChanges event,
    Emitter<CourseInfoEditorState> emit,
  ) async {
    if (!state.isDirty) return;

    emit(state.copyWith(status: CourseInfoEditorStatus.saving));
    try {
      final data = {
        'course_id': state.course.id,
        'title': state.course.title,
        'description': state.course.description,
        'price': state.course.price.toString(),
        if (state.newColor != null)
          'color':
              '#${state.newColor!.value.toRadixString(16).substring(2).toUpperCase()}',
      };

      // **CORRECTION APPLIQUÉE ICI**
      // Utilisation du paramètre nommé `path:` pour l'URL.
      final response = await apiClient.postMultipart(
        path: '/api/v1/edit_course.php',
        data: data,
        imageFile: state.newImageFile,
      );

      final newImageUrl = response.data['new_image_url'];
      final updatedCourse = state.course.copyWith(imageUrl: newImageUrl);

      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.success,
          isDirty: false,
          course: updatedCourse,
          clearImage: true,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.failure,
          error: "Erreur API : ${e.response?.data['message'] ?? e.message}",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.failure,
          error: "Une erreur inattendue est survenue : $e",
        ),
      );
    }
  }
}

//==============================================================================
// LESSON EDITOR
//==============================================================================

// --- EVENTS ---
abstract class LessonEditorEvent extends Equatable {
  const LessonEditorEvent();
  @override
  List<Object?> get props => [];
}

class FetchLessonDetails extends LessonEditorEvent {
  final int lessonId;
  const FetchLessonDetails(this.lessonId);
}

class LessonContentChanged extends LessonEditorEvent {
  final String? contentUrl;
  final String? contentText;

  const LessonContentChanged({this.contentUrl, this.contentText});
}

class SaveLessonContent extends LessonEditorEvent {}

// --- STATES ---
enum LessonEditorStatus { initial, loading, success, failure, saving }

class LessonEditorState extends Equatable {
  final LessonEditorStatus status;
  final LessonEntity lesson;
  final String error;
  final bool isDirty;

  const LessonEditorState({
    this.status = LessonEditorStatus.initial,
    this.lesson = const LessonEntity(
      id: 0,
      title: '',
      lessonType: LessonType.unknown,
    ),
    this.error = '',
    this.isDirty = false,
  });

  LessonEditorState copyWith({
    LessonEditorStatus? status,
    LessonEntity? lesson,
    String? error,
    bool? isDirty,
  }) {
    return LessonEditorState(
      status: status ?? this.status,
      lesson: lesson ?? this.lesson,
      error: error ?? this.error,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [status, lesson, error, isDirty];
}

// --- BLOC ---
class LessonEditorBloc extends Bloc<LessonEditorEvent, LessonEditorState> {
  final ApiClient apiClient;

  LessonEditorBloc({required this.apiClient})
    : super(const LessonEditorState()) {
    on<FetchLessonDetails>(_onFetchLessonDetails);
    on<LessonContentChanged>(_onLessonContentChanged);
    on<SaveLessonContent>(_onSaveLessonContent);
  }

  Future<void> _onFetchLessonDetails(
    FetchLessonDetails event,
    Emitter<LessonEditorState> emit,
  ) async {
    emit(state.copyWith(status: LessonEditorStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_lesson_details.php',
        queryParameters: {'lesson_id': event.lessonId},
      );
      final lesson = LessonEntity.fromJson(response.data);
      emit(
        state.copyWith(
          status: LessonEditorStatus.success,
          lesson: lesson,
          isDirty: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: LessonEditorStatus.failure, error: e.toString()),
      );
    }
  }

  void _onLessonContentChanged(
    LessonContentChanged event,
    Emitter<LessonEditorState> emit,
  ) {
    final newLesson = state.lesson.copyWith(
      contentUrl: event.contentUrl,
      contentText: event.contentText,
    );
    emit(state.copyWith(lesson: newLesson, isDirty: true));
  }

  Future<void> _onSaveLessonContent(
    SaveLessonContent event,
    Emitter<LessonEditorState> emit,
  ) async {
    if (!state.isDirty) return;

    emit(state.copyWith(status: LessonEditorStatus.saving));
    try {
      await apiClient.post(
        '/api/v1/update_lesson_content.php',
        data: {
          'lesson_id': state.lesson.id,
          'content_url': state.lesson.contentUrl,
          'content_text': state.lesson.contentText,
        },
      );
      emit(state.copyWith(status: LessonEditorStatus.success, isDirty: false));
      add(FetchLessonDetails(state.lesson.id));
    } catch (e) {
      emit(
        state.copyWith(status: LessonEditorStatus.failure, error: e.toString()),
      );
    }
  }
}

//==============================================================================
// QUIZ EDITOR
//==============================================================================

// --- EVENTS ---
abstract class QuizEditorEvent extends Equatable {
  const QuizEditorEvent();
  @override
  List<Object> get props => [];
}

class FetchQuizForEditing extends QuizEditorEvent {
  final int lessonId;
  const FetchQuizForEditing(this.lessonId);
}

class QuizChanged extends QuizEditorEvent {
  final QuizEntity updatedQuiz;
  const QuizChanged(this.updatedQuiz);
}

class SaveQuizPressed extends QuizEditorEvent {}

// --- STATES ---
enum QuizEditorStatus { initial, loading, loaded, saving, success, failure }

class QuizEditorState extends Equatable {
  final QuizEditorStatus status;
  final QuizEntity quiz;
  final String error;
  final bool isDirty;

  const QuizEditorState({
    this.status = QuizEditorStatus.initial,
    this.quiz = const QuizEntity(
      id: 0,
      title: '',
      description: '',
      questions: [],
    ),
    this.error = '',
    this.isDirty = false,
  });

  QuizEditorState copyWith({
    QuizEditorStatus? status,
    QuizEntity? quiz,
    String? error,
    bool? isDirty,
  }) {
    return QuizEditorState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      error: error ?? this.error,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [status, quiz, error, isDirty];
}

// --- BLOC ---
class QuizEditorBloc extends Bloc<QuizEditorEvent, QuizEditorState> {
  final ApiClient apiClient;

  QuizEditorBloc({required this.apiClient}) : super(const QuizEditorState()) {
    on<FetchQuizForEditing>(_onFetchQuizForEditing);
    on<QuizChanged>(_onQuizChanged);
    on<SaveQuizPressed>(_onSaveQuizPressed);
  }

  Future<void> _onFetchQuizForEditing(
    FetchQuizForEditing event,
    Emitter<QuizEditorState> emit,
  ) async {
    emit(state.copyWith(status: QuizEditorStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_quiz_details.php',
        queryParameters: {'lesson_id': event.lessonId},
      );
      final quiz = QuizEntity.fromJson(response.data);
      emit(
        state.copyWith(
          status: QuizEditorStatus.loaded,
          quiz: quiz,
          isDirty: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: QuizEditorStatus.failure, error: e.toString()),
      );
    }
  }

  void _onQuizChanged(QuizChanged event, Emitter<QuizEditorState> emit) {
    emit(
      state.copyWith(
        quiz: event.updatedQuiz,
        status: QuizEditorStatus.loaded,
        isDirty: true,
      ),
    );
  }

  Future<void> _onSaveQuizPressed(
    SaveQuizPressed event,
    Emitter<QuizEditorState> emit,
  ) async {
    for (var question in state.quiz.questions) {
      if (question.answers.length < 2) {
        emit(
          state.copyWith(
            status: QuizEditorStatus.failure,
            error:
                "Validation échouée : La question \"${question.text}\" doit avoir au moins 2 réponses.",
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
        emit(state.copyWith(status: QuizEditorStatus.loaded));
        return;
      }

      if (!question.answers.any((answer) => answer.isCorrect)) {
        emit(
          state.copyWith(
            status: QuizEditorStatus.failure,
            error:
                "Validation échouée : La question \"${question.text}\" doit avoir une bonne réponse de sélectionnée.",
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
        emit(state.copyWith(status: QuizEditorStatus.loaded));
        return;
      }
    }

    emit(state.copyWith(status: QuizEditorStatus.saving));
    try {
      await apiClient.post('/api/v1/save_quiz.php', data: state.quiz.toJson());
      emit(state.copyWith(status: QuizEditorStatus.success, isDirty: false));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: QuizEditorStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: QuizEditorStatus.failure,
          error: "Erreur serveur: ${e.toString()}",
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));
      emit(state.copyWith(status: QuizEditorStatus.loaded));
    }
  }
}
