// lib/features/5_messaging/chat_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/5_messaging/messaging_logic.dart';

class ChatPage extends StatelessWidget {
  final int conversationId;
  final ConversationEntity? conversation;

  const ChatPage({super.key, required this.conversationId, this.conversation});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ChatBloc>()..add(FetchMessages(conversationId)),
      child: _ChatView(
        conversationId: conversationId,
        conversation: conversation,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final int conversationId;
  final ConversationEntity? conversation;

  const _ChatView({required this.conversationId, this.conversation});

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Le BLoC est fermé automatiquement par BlocProvider, pas besoin de s'occuper du timer ici.
    super.dispose();
  }

  // Fait défiler la liste vers le bas, utile pour voir les nouveaux messages.
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    // On attend que le frame soit rendu pour être sûr des dimensions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthenticationBloc>().state.user.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation?.conversationName ?? 'Discussion'),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                // Fait défiler vers le bas chaque fois que la liste de messages est mise à jour
                if (state is ChatLoaded) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is ChatLoading || state is ChatInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ChatError) {
                  return Center(child: Text("Erreur: ${state.message}"));
                }
                if (state is ChatLoaded) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text("Envoyez le premier message !"),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isMe = message.senderId.toString() == userId;
                      return MessageBubble(message: message, isMe: isMe);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          _buildMessageInputField(context, userId),
        ],
      ),
    );
  }

  // Le champ de saisie du message
  Widget _buildMessageInputField(BuildContext context, String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // TODO: Ajouter un bouton pour les images plus tard
            // IconButton(icon: Icon(Icons.attach_file), onPressed: (){},),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Votre message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            // Le bouton d'envoi
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                final content = _messageController.text.trim();
                if (content.isNotEmpty) {
                  context.read<ChatBloc>().add(
                    SendMessage(
                      conversationId: widget.conversationId,
                      senderId: userId,
                      content: content,
                    ),
                  );
                  _messageController.clear();
                }
              },
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// La bulle de message
class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          // La couleur change si c'est un message optimiste
          color: message.isOptimistic
              ? Colors.grey.shade400
              : (isMe ? Theme.of(context).primaryColor : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Affiche le nom de l'expéditeur si ce n'est pas moi (et si ce n'est pas un chat de groupe)
            if (!isMe)
              Text(
                message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.white : Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
            if (!isMe) const SizedBox(height: 2),
            // Le contenu du message
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            // L'heure et le statut d'envoi
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
                // AFFICHE "Envoi..." SI LE MESSAGE EST OPTIMISTE
                if (message.isOptimistic)
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text(
                      "(Envoi...)",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
