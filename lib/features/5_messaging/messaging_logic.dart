// lib/features/5_messaging/messaging_logic.dart
import 'dart:async';
import 'package:collection/collection.dart'; // Import pour listEquals
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';

//==============================================================================
// ENTITIES
//==============================================================================

class ConversationEntity extends Equatable {
  final int id;
  final String conversationName;
  final String? conversationImageUrl;
  final String type; // 'individual' or 'group'
  final String lastMessage;
  final DateTime? lastMessageAt;

  const ConversationEntity({
    required this.id,
    required this.conversationName,
    this.conversationImageUrl,
    required this.type,
    required this.lastMessage,
    this.lastMessageAt,
  });

  factory ConversationEntity.fromJson(Map<String, dynamic> json) {
    return ConversationEntity(
      id: json['id'],
      conversationName: json['conversation_name'],
      conversationImageUrl: json['conversation_image_url'],
      type: json['type'],
      lastMessage: json['last_message'] ?? '',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    conversationName,
    conversationImageUrl,
    type,
    lastMessage,
    lastMessageAt,
  ];
}

class MessageEntity extends Equatable {
  final int id;
  final int senderId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String senderName;
  final String? senderImageUrl;
  final bool
  isOptimistic; // NOUVEAU: Pour marquer les messages en cours d'envoi

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.senderName,
    this.senderImageUrl,
    this.isOptimistic = false, // Valeur par défaut
  });

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    return MessageEntity(
      id: json['id'],
      senderId: json['sender_id'],
      content: json['content'] ?? '', // S'assurer que content n'est jamais null
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
      senderImageUrl: json['sender_image_url'],
    );
  }

  // Copie de l'objet en modifiant certaines propriétés
  MessageEntity copyWith({int? id, bool? isOptimistic}) {
    return MessageEntity(
      id: id ?? this.id,
      senderId: senderId,
      content: content,
      imageUrl: imageUrl,
      createdAt: createdAt,
      senderName: senderName,
      senderImageUrl: senderImageUrl,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    content,
    imageUrl,
    createdAt,
    senderName,
    senderImageUrl,
    isOptimistic,
  ];
}

//==============================================================================
// CONVERSATIONS BLOC (Inchangé, mais inclus pour la complétude du fichier)
//==============================================================================
abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();
  @override
  List<Object> get props => [];
}

class FetchConversations extends ConversationsEvent {
  final String userId;
  const FetchConversations(this.userId);
}

abstract class ConversationsState extends Equatable {
  const ConversationsState();
  @override
  List<Object> get props => [];
}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {}

class ConversationsLoaded extends ConversationsState {
  final List<ConversationEntity> conversations;
  const ConversationsLoaded(this.conversations);
}

class ConversationsError extends ConversationsState {
  final String message;
  const ConversationsError(this.message);
}

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final ApiClient apiClient;

  ConversationsBloc({required this.apiClient}) : super(ConversationsInitial()) {
    on<FetchConversations>(_onFetchConversations);
  }

  Future<void> _onFetchConversations(
    FetchConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(ConversationsLoading());
    try {
      final response = await apiClient.get(
        '/api/v1/get_conversations.php',
        queryParameters: {'user_id': event.userId},
      );
      final conversations = (response.data as List)
          .map((json) => ConversationEntity.fromJson(json))
          .toList();
      emit(ConversationsLoaded(conversations));
    } catch (e) {
      emit(
        ConversationsError(
          "Erreur de chargement des conversations: ${e.toString()}",
        ),
      );
    }
  }
}

//==============================================================================
// CHAT BLOC (Logique entièrement revue)
//==============================================================================
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class FetchMessages extends ChatEvent {
  final int conversationId;
  const FetchMessages(this.conversationId);
}

class SendMessage extends ChatEvent {
  final int conversationId;
  final String senderId;
  final String content;
  final String? imageUrl;
  const SendMessage({
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.imageUrl,
  });
}

class _MessagesUpdated extends ChatEvent {
  final List<MessageEntity> messages;
  const _MessagesUpdated(this.messages);
}

class _SendMessageError extends ChatEvent {
  final int optimisticId;
  const _SendMessageError(this.optimisticId);
}

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<MessageEntity> messages;
  const ChatLoaded(this.messages);
  @override
  List<Object> get props => [messages];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiClient apiClient;
  Timer? _pollingTimer;

  ChatBloc({required this.apiClient}) : super(ChatInitial()) {
    on<FetchMessages>(_onFetchMessages);
    on<SendMessage>(_onSendMessage);
    on<_MessagesUpdated>(_onMessagesUpdated);
    on<_SendMessageError>(_onSendMessageError);
  }

  void _onFetchMessages(FetchMessages event, Emitter<ChatState> emit) async {
    // Affiche le loader uniquement si c'est le premier chargement.
    if (state is! ChatLoaded) {
      emit(ChatLoading());
    }

    try {
      final response = await apiClient.get(
        '/api/v1/get_messages.php',
        queryParameters: {'conversation_id': event.conversationId},
      );
      final messages = (response.data as List)
          .map((json) => MessageEntity.fromJson(json))
          .toList();

      add(_MessagesUpdated(messages));

      // Démarrer le polling pour les mises à jour en direct
      _startPolling(event.conversationId);
    } catch (e) {
      if (state is! ChatLoaded) {
        emit(ChatError("Erreur de chargement des messages: ${e.toString()}"));
      }
      // Si une erreur survient pendant le polling, on ne bloque pas l'écran
    }
  }

  void _onMessagesUpdated(_MessagesUpdated event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentMessages = (state as ChatLoaded).messages;
      // On ne met à jour l'état que si la liste de messages a réellement changé.
      if (!const ListEquality().equals(currentMessages, event.messages)) {
        emit(ChatLoaded(event.messages));
      }
    } else {
      emit(ChatLoaded(event.messages));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded)
      return; // Ne pas envoyer si les messages ne sont pas chargés

    final currentUser = sl<AuthenticationBloc>().state.user;
    final optimisticId = DateTime.now().millisecondsSinceEpoch;

    // 1. Créer le message optimiste (temporaire)
    final optimisticMessage = MessageEntity(
      id: optimisticId, // ID temporaire unique
      senderId: int.parse(event.senderId),
      content: event.content,
      imageUrl: event.imageUrl,
      createdAt: DateTime.now(),
      senderName: currentUser.name, // Nom de l'utilisateur actuel
      isOptimistic: true, // Marqué comme en cours d'envoi
    );

    // 2. Mettre à jour l'UI immédiatement avec ce message temporaire
    final currentMessages = (state as ChatLoaded).messages;
    emit(ChatLoaded(List.from(currentMessages)..add(optimisticMessage)));

    try {
      // 3. Envoyer le message au serveur
      final response = await apiClient.post(
        '/api/v1/send_message.php',
        data: {
          'conversation_id': event.conversationId,
          'sender_id': event.senderId,
          'content': event.content,
          'image_url': event.imageUrl,
        },
      );

      // 4. Le serveur renvoie le message confirmé (avec le vrai ID, etc.)
      final confirmedMessage = MessageEntity.fromJson(
        response.data['sent_message'],
      );

      // 5. Remplacer le message optimiste par le message confirmé dans la liste
      final newMessages = (state as ChatLoaded).messages.map((msg) {
        return msg.id == optimisticId ? confirmedMessage : msg;
      }).toList();

      emit(ChatLoaded(newMessages));
    } catch (e) {
      // 6. Gérer l'échec de l'envoi
      // Pour l'instant, on retire juste le message qui a échoué
      final finalMessages = (state as ChatLoaded).messages
          .where((msg) => msg.id != optimisticId)
          .toList();
      emit(ChatLoaded(finalMessages));
      // Idéalement, on ajouterait ici un événement pour afficher une SnackBar d'erreur.
    }
  }

  void _startPolling(int conversationId) {
    _pollingTimer?.cancel();
    // On vérifie les nouveaux messages toutes les 5 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // On ne lance pas un nouveau fetch si le précédent n'est pas terminé
      // ou si l'état n'est pas "chargé".
      if (state is ChatLoaded) {
        add(FetchMessages(conversationId));
      }
    });
  }

  void _onSendMessageError(_SendMessageError event, Emitter<ChatState> emit) {
    // Cette partie pourrait être utilisée pour marquer un message comme "échec d'envoi"
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
