// lib/features/shared/stripe_logic.dart
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
// Import pour url_launcher
import 'package:url_launcher/url_launcher.dart';
// On garde l'import de flutter_stripe pour les autres fonctionnalités
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
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      if (e.response?.statusCode == 404) {
        emit(
          const StripeStatusLoaded(
            StripeAccountStatus(detailsSubmitted: false, payoutsEnabled: false),
          ),
        );
      } else {
        emit(StripeError(e.toString()));
      }
    } catch (e) {
      emit(StripeError(e.toString()));
    }
  }

  Future<void> _onInitiateCheckout(
    InitiateCheckout event,
    Emitter<StripeState> emit,
  ) async {
    emit(StripeCheckoutInProgress());
    try {
      // 1. Appeler votre backend pour créer la session de paiement
      final response = await apiClient.post(
        '/api/v1/create_checkout_session.php',
        data: {'course_id': event.courseId, 'user_id': event.userId},
      );

      // 2. Récupérer l'URL complète retournée par le backend
      final checkoutUrl = response.data['url'];
      if (checkoutUrl == null) {
        throw Exception('URL de paiement non trouvée dans la réponse.');
      }

      final uri = Uri.parse(checkoutUrl);

      // 3. Lancer l'URL dans une vue web intégrée (in-app)
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView, // Ouvre dans l'app
        );
      } else {
        throw Exception('Impossible de lancer l\'URL : $checkoutUrl');
      }

      // Une fois que l'utilisateur a fini et revient à l'app, on réinitialise l'état.
      // La confirmation de l'achat est gérée par le webhook Stripe sur votre serveur.
      emit(StripeInitial());
    } catch (e) {
      emit(
        StripeError("Erreur lors du lancement du paiement : ${e.toString()}"),
      );
      // On remet l'état initial pour permettre une nouvelle tentative
      emit(StripeInitial());
    }
  }
}
