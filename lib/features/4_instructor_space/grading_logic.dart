// lib/features/4_instructor_space/grading_logic.dart
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';

//==============================================================================
// ENTITIES
//==============================================================================

/// Entité représentant le feedback de l'instructeur.
class InstructorFeedbackEntity extends Equatable {
  final Map<String, String> comments; // Map<localBlockId, commentText>
  final List<ContentBlockEntity> files;
  final String generalComment;

  const InstructorFeedbackEntity({
    this.comments = const {},
    this.files = const [],
    this.generalComment = '',
  });

  factory InstructorFeedbackEntity.fromJson(Map<String, dynamic> json) {
    return InstructorFeedbackEntity(
      comments: Map<String, String>.from(json['comments'] ?? {}),
      files: (json['files'] as List? ?? [])
          .map((fileJson) => ContentBlockEntity.fromJson(fileJson))
          .toList(),
      generalComment: json['general_comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comments': comments,
      'files': files.map((file) => file.toJson()).toList(),
      'general_comment': generalComment,
    };
  }

  InstructorFeedbackEntity copyWith({
    Map<String, String>? comments,
    List<ContentBlockEntity>? files,
    String? generalComment,
  }) {
    return InstructorFeedbackEntity(
      comments: comments ?? this.comments,
      files: files ?? this.files,
      generalComment: generalComment ?? this.generalComment,
    );
  }

  @override
  List<Object?> get props => [comments, files, generalComment];
}

/// Entité complète pour un rendu en cours de correction.
class GradingSubmissionEntity extends Equatable {
  final int id;
  final int studentId; // Ajout de l'ID de l'étudiant
  final String lessonTitle;
  final LessonType lessonType;
  final List<ContentBlockEntity> studentContent;
  final List<ContentBlockEntity> lessonStatement; // L'énoncé original
  final InstructorFeedbackEntity? instructorFeedback;
  final double? grade;
  final int? associatedQuizId; // Ajout de l'ID du quiz associé

  const GradingSubmissionEntity({
    required this.id,
    required this.studentId,
    required this.lessonTitle,
    required this.lessonType,
    required this.studentContent,
    required this.lessonStatement,
    this.instructorFeedback,
    this.grade,
    this.associatedQuizId,
  });

  factory GradingSubmissionEntity.fromJson(Map<String, dynamic> json) {
    return GradingSubmissionEntity(
      id: json['id'],
      studentId: int.parse(json['student_id'].toString()),
      lessonTitle: json['lesson_title'],
      lessonType: LessonEntity.lessonTypeFromString(json['lesson_type']),
      studentContent: (json['content'] as List? ?? [])
          .map((block) => ContentBlockEntity.fromJson(block))
          .toList(),
      lessonStatement: (json['lesson_enonce'] as List? ?? [])
          .map((block) => ContentBlockEntity.fromJson(block))
          .toList(),
      instructorFeedback: json['instructor_feedback'] != null
          ? InstructorFeedbackEntity.fromJson(json['instructor_feedback'])
          : const InstructorFeedbackEntity(),
      // CORRECTION : Utilisation de `double.tryParse` pour une conversion plus sûre.
      grade: json['grade'] != null
          ? double.tryParse(json['grade'].toString())
          : null,
      associatedQuizId: json['associated_quiz_id'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    lessonTitle,
    lessonType,
    studentContent,
    lessonStatement,
    instructorFeedback,
    grade,
    associatedQuizId,
  ];
}

//==============================================================================
// BLOC
//==============================================================================

// --- EVENTS ---
abstract class GradingEvent extends Equatable {
  const GradingEvent();
  @override
  List<Object?> get props => [];
}

class FetchSubmissionDetails extends GradingEvent {
  final int submissionId;
  const FetchSubmissionDetails(this.submissionId);
}

class UpdateFeedback extends GradingEvent {
  final InstructorFeedbackEntity feedback;
  const UpdateFeedback(this.feedback);
}

class UpdateGrade extends GradingEvent {
  final double? grade;
  const UpdateGrade(this.grade);
}

class UploadCorrectionFile extends GradingEvent {
  final XFile file;
  const UploadCorrectionFile(this.file);
}

class RemoveCorrectionFile extends GradingEvent {
  final String localFileId;
  const RemoveCorrectionFile(this.localFileId);
}

class SaveCorrection extends GradingEvent {}

// --- STATES ---
enum GradingStatus { initial, loading, loaded, saving, success, failure }

class GradingState extends Equatable {
  final GradingStatus status;
  final GradingSubmissionEntity submission;
  final InstructorFeedbackEntity feedback;
  final double? grade;
  final String error;

  const GradingState({
    this.status = GradingStatus.initial,
    this.submission = const GradingSubmissionEntity(
      id: 0,
      studentId: 0,
      lessonTitle: '',
      lessonType: LessonType.unknown,
      studentContent: [],
      lessonStatement: [],
    ),
    this.feedback = const InstructorFeedbackEntity(),
    this.grade,
    this.error = '',
  });

  GradingState copyWith({
    GradingStatus? status,
    GradingSubmissionEntity? submission,
    InstructorFeedbackEntity? feedback,
    double? grade,
    bool clearGrade = false,
    String? error,
  }) {
    return GradingState(
      status: status ?? this.status,
      submission: submission ?? this.submission,
      feedback: feedback ?? this.feedback,
      grade: clearGrade ? null : grade ?? this.grade,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, submission, feedback, grade, error];
}

// --- BLOC ---
class GradingBloc extends Bloc<GradingEvent, GradingState> {
  final ApiClient apiClient;

  GradingBloc({required this.apiClient}) : super(const GradingState()) {
    on<FetchSubmissionDetails>(_onFetchSubmissionDetails);
    on<UpdateFeedback>(_onUpdateFeedback);
    on<UpdateGrade>(_onUpdateGrade);
    on<UploadCorrectionFile>(_onUploadCorrectionFile);
    on<RemoveCorrectionFile>(_onRemoveCorrectionFile);
    on<SaveCorrection>(_onSaveCorrection);
  }

  Future<void> _onFetchSubmissionDetails(
    FetchSubmissionDetails event,
    Emitter<GradingState> emit,
  ) async {
    emit(state.copyWith(status: GradingStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_submission_details.php',
        queryParameters: {'submission_id': event.submissionId},
      );
      final submission = GradingSubmissionEntity.fromJson(response.data);
      emit(
        state.copyWith(
          status: GradingStatus.loaded,
          submission: submission,
          feedback: submission.instructorFeedback,
          grade: submission.grade,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: GradingStatus.failure, error: e.toString()));
    }
  }

  void _onUpdateFeedback(UpdateFeedback event, Emitter<GradingState> emit) {
    emit(state.copyWith(feedback: event.feedback));
  }

  void _onUpdateGrade(UpdateGrade event, Emitter<GradingState> emit) {
    emit(state.copyWith(grade: event.grade));
  }

  Future<void> _onUploadCorrectionFile(
    UploadCorrectionFile event,
    Emitter<GradingState> emit,
  ) async {
    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempFileBlock = ContentBlockEntity(
      id: 0,
      localId: localId,
      blockType: ContentBlockType.document,
      content: event.file.name,
      orderIndex: state.feedback.files.length,
      uploadStatus: UploadStatus.uploading,
      metadata: {'fileName': event.file.name},
    );

    final updatedFiles = List<ContentBlockEntity>.from(state.feedback.files)
      ..add(tempFileBlock);
    emit(
      state.copyWith(feedback: state.feedback.copyWith(files: updatedFiles)),
    );

    try {
      final response = await apiClient.postMultipart(
        path: '/api/v1/upload_file.php',
        data: {},
        file: event.file,
      );
      final fileUrl = response.data['url'];
      final finalBlock = tempFileBlock.copyWith(
        content: fileUrl,
        uploadStatus: UploadStatus.completed,
      );

      final listToUpdate = List<ContentBlockEntity>.from(state.feedback.files);
      final index = listToUpdate.indexWhere((b) => b.localId == localId);
      if (index != -1) {
        listToUpdate[index] = finalBlock;
        emit(
          state.copyWith(
            feedback: state.feedback.copyWith(files: listToUpdate),
          ),
        );
      }
    } catch (e) {
      final failedBlock = tempFileBlock.copyWith(
        uploadStatus: UploadStatus.failed,
      );
      final listToUpdate = List<ContentBlockEntity>.from(state.feedback.files);
      final index = listToUpdate.indexWhere((b) => b.localId == localId);
      if (index != -1) {
        listToUpdate[index] = failedBlock;
        emit(
          state.copyWith(
            feedback: state.feedback.copyWith(files: listToUpdate),
          ),
        );
      }
    }
  }

  void _onRemoveCorrectionFile(
    RemoveCorrectionFile event,
    Emitter<GradingState> emit,
  ) {
    final updatedFiles = state.feedback.files
        .where((f) => f.localId != event.localFileId)
        .toList();
    emit(
      state.copyWith(feedback: state.feedback.copyWith(files: updatedFiles)),
    );
  }

  Future<void> _onSaveCorrection(
    SaveCorrection event,
    Emitter<GradingState> emit,
  ) async {
    emit(state.copyWith(status: GradingStatus.saving));
    try {
      final payload = {
        'submission_id': state.submission.id,
        'grade': state.grade,
        'feedback': state.feedback.toJson(),
      };
      await apiClient.post('/api/v1/grade_submission.php', data: payload);
      emit(state.copyWith(status: GradingStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: GradingStatus.failure,
          error: "Erreur lors de la sauvegarde: ${e.toString()}",
        ),
      );
    }
  }
}
