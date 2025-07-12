// lib/features/5_messaging/conversations_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/5_messaging/messaging_logic.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthenticationBloc>().state.user.id;
    return BlocProvider(
      create: (context) =>
          sl<ConversationsBloc>()..add(FetchConversations(userId)),
      child: DefaultTabController(
        length: 2, // Deux onglets : Messages et Groupes
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Messagerie'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                tooltip: 'Mon Profil',
                onPressed: () => context.push('/profile'),
              ),
            ],
            // La TabBar pour les onglets
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.person), text: 'Messages'),
                Tab(icon: Icon(Icons.group), text: 'Groupes'),
              ],
            ),
          ),
          // Le corps contient la vue des onglets
          body: TabBarView(
            children: [
              // Contenu pour l'onglet "Messages" (individuels)
              _ConversationListView(type: 'individual', userId: userId),
              // Contenu pour l'onglet "Groupes"
              _ConversationListView(type: 'group', userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget interne pour afficher la liste des conversations filtrée par type.
class _ConversationListView extends StatelessWidget {
  final String type;
  final String userId;

  const _ConversationListView({required this.type, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationsBloc, ConversationsState>(
      builder: (context, state) {
        if (state is ConversationsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ConversationsError) {
          return Center(child: Text(state.message));
        }
        if (state is ConversationsLoaded) {
          // On filtre les conversations en fonction du type de l'onglet
          final filteredConversations = state.conversations
              .where((c) => c.type == type)
              .toList();

          if (filteredConversations.isEmpty) {
            return Center(
              child: Text(
                type == 'group'
                    ? "Vous n'êtes dans aucun groupe de discussion."
                    : "Vous n'avez aucune conversation.",
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ConversationsBloc>().add(FetchConversations(userId));
            },
            child: ListView.builder(
              itemCount: filteredConversations.length,
              itemBuilder: (context, index) {
                final conversation = filteredConversations[index];
                return ConversationTile(conversation: conversation);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Widget pour une seule ligne de conversation (tuile).
class ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;

  const ConversationTile({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: conversation.conversationImageUrl != null
            ? NetworkImage(conversation.conversationImageUrl!)
            : null,
        child: conversation.conversationImageUrl == null
            ? Text(conversation.conversationName.substring(0, 1).toUpperCase())
            : null,
      ),
      title: Text(
        conversation.conversationName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        conversation.lastMessageAt != null
            ? DateFormat('HH:mm').format(conversation.lastMessageAt!.toLocal())
            : '',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        context.push('/chat/${conversation.id}', extra: conversation);
      },
    );
  }
}
