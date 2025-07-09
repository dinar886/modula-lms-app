// lib/features/shared/stripe_logic.dart
import 'package:dio/dio.dart'; // NOUVEL IMPORT
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// --- ENTITY ---
class StripeAccountStatus extends Equatable {
  final bool detailsSubmitted;
  final bool payoutsEnabled;

  const StripeAccountStatus({
    required this.detailsSubmitted,
    required this.payoutsEnabled,
  });

  factory StripeAccountStatus.fromJson(Map<String, dynamic> json) {
    return StripeAccountStatus(
      detailsSubmitted: json['details_submitted'] ?? false,
      payoutsEnabled: json['payouts_enabled'] ?? false,
    );
  }

  @override
  List<Object> get props => [detailsSubmitted, payoutsEnabled];
}

// --- EVENTS ---
abstract class StripeEvent extends Equatable {
  const StripeEvent();
  @override
  List<Object> get props => [];
}

class CreateStripeConnectAccount extends StripeEvent {
  final String userId;
  final String email;
  const CreateStripeConnectAccount({required this.userId, required this.email});
}

class FetchStripeAccountStatus extends StripeEvent {
  final String userId;
  const FetchStripeAccountStatus({required this.userId});
}

class InitiateCheckout extends StripeEvent {
  final String courseId;
  final String userId;

  const InitiateCheckout({required this.courseId, required this.userId});
}

// --- STATES ---
abstract class StripeState extends Equatable {
  const StripeState();
  @override
  List<Object?> get props => [];
}

class StripeInitial extends StripeState {}

class StripeLoading extends StripeState {}

class StripeAccountLinkCreated extends StripeState {
  final String onboardingUrl;
  const StripeAccountLinkCreated(this.onboardingUrl);
}

class StripeStatusLoaded extends StripeState {
  final StripeAccountStatus status;
  const StripeStatusLoaded(this.status);
}

class StripeCheckoutInProgress extends StripeState {}

class StripeError extends StripeState {
  final String message;
  const StripeError(this.message);
}

// --- BLOC ---
class StripeBloc extends Bloc<StripeEvent, StripeState> {
  final ApiClient apiClient;

  StripeBloc({required this.apiClient}) : super(StripeInitial()) {
    on<CreateStripeConnectAccount>(_onCreateStripeConnectAccount);
    on<FetchStripeAccountStatus>(_onFetchStripeAccountStatus);
    on<InitiateCheckout>(_onInitiateCheckout);
  }

  Future<void> _onCreateStripeConnectAccount(
    CreateStripeConnectAccount event,
    Emitter<StripeState> emit,
  ) async {
    emit(StripeLoading());
    try {
      final response = await apiClient.post(
        '/api/v1/create_stripe_connect_account.php',
        data: {'user_id': event.userId, 'email': event.email},
      );
      final url = response.data['onboarding_url'];
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, webOnlyWindowName: '_self');
      } else {
        throw Exception("Impossible d'ouvrir le lien de configuration.");
      }
      emit(StripeAccountLinkCreated(url));
    } catch (e) {
      emit(
        StripeError("Erreur lors de la création du compte : ${e.toString()}"),
      );
    }
  }

  Future<void> _onFetchStripeAccountStatus(
    FetchStripeAccountStatus event,
    Emitter<StripeState> emit,
  ) async {
    emit(StripeLoading());
    try {
      final response = await apiClient.get(
        '/api/v1/get_stripe_account_status.php',
        queryParameters: {'user_id': event.userId},
      );
      final status = StripeAccountStatus.fromJson(response.data);
      emit(StripeStatusLoaded(status));
    } on DioException catch (e) {
      // *** CORRECTION APPLIQUÉE ICI ***
      // Si l'erreur est 404, cela signifie que le formateur n'a pas encore de compte.
      // Ce n'est pas une erreur fatale, on affiche simplement l'état initial.
      if (e.response?.statusCode == 404) {
        emit(
          const StripeStatusLoaded(
            StripeAccountStatus(detailsSubmitted: false, payoutsEnabled: false),
          ),
        );
      } else {
        // Pour toute autre erreur de Dio, on l'affiche.
        emit(StripeError(e.toString()));
      }
    } catch (e) {
      // Pour les autres types d'erreurs.
      emit(StripeError(e.toString()));
    }
  }

  Future<void> _onInitiateCheckout(
    InitiateCheckout event,
    Emitter<StripeState> emit,
  ) async {
    emit(StripeCheckoutInProgress());
    try {
      final response = await apiClient.post(
        '/api/v1/create_checkout_session.php',
        data: {'course_id': event.courseId, 'user_id': event.userId},
      );
      final sessionId = response.data['id'];
      final checkoutUrl = 'https://checkout.stripe.com/pay/$sessionId';
      final uri = Uri.parse(checkoutUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("Impossible d'ouvrir la page de paiement.");
      }

      emit(StripeInitial());
    } catch (e) {
      emit(StripeError("Erreur lors du paiement : ${e.toString()}"));
      emit(StripeInitial());
    }
  }
}
