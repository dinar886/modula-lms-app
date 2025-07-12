// lib/features/4_instructor_space/students_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/4_instructor_space/students_logic.dart';
import 'package:modula_lms/features/5_messaging/messaging_logic.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<bool> _isPanelOpen = [];

  Color _getColorForStudent(String studentId) {
    const List<Color> avatarColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    final int colorIndex = studentId.hashCode % avatarColors.length;
    return avatarColors[colorIndex];
  }

  // NOUVELLE FONCTION : Pour démarrer un chat
  void _startChatWithStudent(
    BuildContext context,
    StudentEntity student,
  ) async {
    final instructorId = context.read<AuthenticationBloc>().state.user.id;
    final apiClient = sl<ApiClient>(); // On récupère l'ApiClient

    try {
      final response = await apiClient.post(
        '/api/v1/create_or_get_individual_chat.php',
        data: {'user1_id': instructorId, 'user2_id': student.id},
      );
      final conversationId = response.data['conversation_id'];

      // Créer une entité conversation pour la passer à la page de chat
      final conversation = ConversationEntity(
        id: conversationId,
        conversationName: student.name,
        conversationImageUrl: student.profileImageUrl,
        type: 'individual',
        lastMessage: '',
        lastMessageAt: DateTime.now(),
      );

      // On navigue vers la page de chat
      context.push('/chat/$conversationId', extra: conversation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur au démarrage du chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructorId = context.read<AuthenticationBloc>().state.user.id;

    return BlocProvider(
      create: (context) =>
          sl<InstructorStudentsBloc>()
            ..add(FetchInstructorStudents(instructorId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Élèves'),
          // On ajoute un bouton pour accéder à son propre profil
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mon Profil',
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: BlocBuilder<InstructorStudentsBloc, InstructorStudentsState>(
          builder: (context, state) {
            if (state is InstructorStudentsLoading ||
                state is InstructorStudentsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is InstructorStudentsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (state is InstructorStudentsLoaded) {
              if (_isPanelOpen.length != state.coursesWithStudents.length) {
                _isPanelOpen = List.generate(
                  state.coursesWithStudents.length,
                  (_) => false,
                );
              }
              if (state.coursesWithStudents.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      "Aucun élève n'est encore inscrit à vos cours.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: ExpansionPanelList(
                  animationDuration: const Duration(milliseconds: 300),
                  elevation: 2,
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _isPanelOpen[panelIndex] = !_isPanelOpen[panelIndex];
                    });
                  },
                  children: state.coursesWithStudents.asMap().entries.map((
                    entry,
                  ) {
                    final int courseIndex = entry.key;
                    final CourseWithStudentsEntity courseWithStudents =
                        entry.value;
                    return ExpansionPanel(
                      isExpanded: _isPanelOpen[courseIndex],
                      canTapOnHeader: true,
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                          title: Text(
                            courseWithStudents.courseTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${courseWithStudents.students.length} élève(s) inscrit(s)",
                          ),
                          trailing: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                        );
                      },
                      body: Column(
                        children: courseWithStudents.students.map((student) {
                          final hasImage =
                              student.profileImageUrl != null &&
                              student.profileImageUrl!.isNotEmpty;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorForStudent(student.id),
                              backgroundImage: hasImage
                                  ? NetworkImage(student.profileImageUrl!)
                                  : null,
                              child: !hasImage
                                  ? Text(
                                      student.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(student.name),
                            subtitle: Text(student.email),
                            // --- NOUVEAU BOUTON DE MESSAGERIE ---
                            trailing: IconButton(
                              icon: const Icon(Icons.message_outlined),
                              onPressed: () =>
                                  _startChatWithStudent(context, student),
                              tooltip: 'Envoyer un message',
                            ),
                            onTap: () {
                              context.push('/students/${student.id}');
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
