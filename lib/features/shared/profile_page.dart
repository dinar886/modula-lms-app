// lib/features/shared/profile_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Contrôleurs pour les champs de texte en mode édition
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  // État pour gérer le mode édition et la nouvelle image
  bool _isEditing = false;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    // On initialise les contrôleurs avec les données de l'utilisateur actuel
    final user = context.read<AuthenticationBloc>().state.user;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Fonction pour sélectionner une image depuis la galerie
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // On utilise BlocProvider pour créer une instance de AuthBloc
    // qui gérera la logique de mise à jour du profil.
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Modifier le Profil' : 'Profil'),
          actions: [
            // On écoute l'état de l'AuthenticationBloc global
            BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, authState) {
                if (authState.user.isNotEmpty) {
                  // Affiche un bouton différent selon le mode (édition ou affichage)
                  return IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        // Si on annule l'édition, on réinitialise les valeurs
                        if (!_isEditing) {
                          final user = context
                              .read<AuthenticationBloc>()
                              .state
                              .user;
                          _nameController.text = user.name;
                          _emailController.text = user.email;
                          _imageFile = null;
                        }
                      });
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Bouton de déconnexion
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthenticationBloc>().add(
                  AuthenticationLogoutRequested(),
                );
              },
            ),
          ],
        ),
        // Le corps de la page utilise un BlocConsumer pour écouter les changements d'état
        // du AuthBloc (pour la mise à jour) et reconstruire l'interface.
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state is AuthSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message ?? "Opération réussie"),
                  backgroundColor: Colors.green,
                ),
              );
              // On quitte le mode édition après une sauvegarde réussie
              setState(() {
                _isEditing = false;
                _imageFile = null;
              });
            }
          },
          builder: (context, profileUpdateState) {
            // On écoute aussi le Bloc global pour avoir les données utilisateur à jour
            return BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, authState) {
                if (authState.user.isEmpty) {
                  return const Center(
                    child: Text('Vous n\'êtes pas connecté.'),
                  );
                }

                // On met à jour les contrôleurs si l'utilisateur change (après sauvegarde)
                if (!_isEditing) {
                  _nameController.text = authState.user.name;
                  _emailController.text = authState.user.email;
                }

                return ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    const SizedBox(height: 20),
                    // --- AVATAR ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _buildAvatarImage(authState.user),
                            child:
                                _imageFile == null &&
                                    (authState.user.profileImageUrl == null ||
                                        authState.user.profileImageUrl!.isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                            backgroundColor: Colors.grey.shade300,
                          ),
                          // Affiche un bouton pour changer l'image en mode édition
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap: _pickImage,
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- CHAMPS D'INFORMATIONS ---
                    _buildInfoField(
                      context: context,
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person_outline,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoField(
                      context: context,
                      controller: _emailController,
                      label: 'Adresse Email',
                      icon: Icons.email_outlined,
                      isEditing: _isEditing,
                    ),

                    const SizedBox(height: 40),

                    // --- BOUTON DE SAUVEGARDE ---
                    if (_isEditing)
                      profileUpdateState is AuthLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text(
                                'Enregistrer les modifications',
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                context.read<AuthBloc>().add(
                                  ProfileUpdateRequested(
                                    userId: authState.user.id,
                                    name: _nameController.text,
                                    email: _emailController.text,
                                    imageFile: _imageFile,
                                  ),
                                );
                              },
                            ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Helper pour construire l'image de l'avatar
  ImageProvider? _buildAvatarImage(User user) {
    if (_imageFile != null) {
      return FileImage(File(_imageFile!.path));
    }
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return NetworkImage(user.profileImageUrl!);
    }
    return null;
  }

  // Widget réutilisable pour afficher un champ d'information (soit en texte, soit en champ de saisie)
  Widget _buildInfoField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEditing,
  }) {
    if (isEditing) {
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
