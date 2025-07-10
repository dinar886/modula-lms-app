// lib/features/4_instructor_space/instructor_dashboard_logic.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';

//==============================================================================
// ENTITY
//==============================================================================

/// Représente les statistiques affichées sur le tableau de bord de l'instructeur.
class InstructorStatsEntity extends Equatable {
  final int totalStudents;
  final int pendingSubmissions;
  final double recentRevenue;

  const InstructorStatsEntity({
    required this.totalStudents,
    required this.pendingSubmissions,
    required this.recentRevenue,
  });

  /// Un constructeur factory pour créer une instance à partir d'un JSON.
  factory InstructorStatsEntity.fromJson(Map<String, dynamic> json) {
    return InstructorStatsEntity(
      totalStudents: json['total_students'] as int,
      pendingSubmissions: json['pending_submissions'] as int,
      recentRevenue: (json['recent_revenue'] as num).toDouble(),
    );
  }

  @override
  List<Object> get props => [totalStudents, pendingSubmissions, recentRevenue];
}

//==============================================================================
// BLOC
//==============================================================================

// --- EVENTS ---

abstract class InstructorDashboardEvent extends Equatable {
  const InstructorDashboardEvent();
  @override
  List<Object> get props => [];
}

/// Événement pour demander le chargement des statistiques.
class FetchInstructorStats extends InstructorDashboardEvent {
  final String instructorId;
  const FetchInstructorStats(this.instructorId);
}

// --- STATES ---

abstract class InstructorDashboardState extends Equatable {
  const InstructorDashboardState();
  @override
  List<Object> get props => [];
}

class InstructorDashboardInitial extends InstructorDashboardState {}

class InstructorDashboardLoading extends InstructorDashboardState {}

/// État lorsque les statistiques sont chargées avec succès.
class InstructorDashboardLoaded extends InstructorDashboardState {
  final InstructorStatsEntity stats;
  const InstructorDashboardLoaded(this.stats);
}

/// État en cas d'erreur.
class InstructorDashboardError extends InstructorDashboardState {
  final String message;
  const InstructorDashboardError(this.message);
}

// --- BLOC ---

/// Gère la logique pour le tableau de bord de l'instructeur.
class InstructorDashboardBloc
    extends Bloc<InstructorDashboardEvent, InstructorDashboardState> {
  final ApiClient apiClient;

  InstructorDashboardBloc({required this.apiClient})
    : super(InstructorDashboardInitial()) {
    on<FetchInstructorStats>(_onFetchInstructorStats);
  }

  /// Gère la récupération des statistiques depuis l'API.
  Future<void> _onFetchInstructorStats(
    FetchInstructorStats event,
    Emitter<InstructorDashboardState> emit,
  ) async {
    emit(InstructorDashboardLoading());
    try {
      final response = await apiClient.get(
        '/api/v1/get_instructor_dashboard_stats.php',
        queryParameters: {'instructor_id': event.instructorId},
      );
      final stats = InstructorStatsEntity.fromJson(response.data);
      emit(InstructorDashboardLoaded(stats));
    } catch (e) {
      emit(
        InstructorDashboardError(
          "Impossible de charger les statistiques: ${e.toString()}",
        ),
      );
    }
  }
}
