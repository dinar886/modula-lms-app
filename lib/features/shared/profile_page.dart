// lib/features/shared/profile_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/shared/stripe_logic.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// *** CORRECTION 1 : On ajoute "with WidgetsBindingObserver" ***
// Cela permet à notre widget d'écouter les changements de cycle de vie de l'application (ex: mise en avant-plan).
class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  bool _isEditing = false;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthenticationBloc>().state.user;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);

    // *** CORRECTION 2 : On enregistre l'observateur ***
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();

    // *** CORRECTION 3 : On supprime l'observateur pour éviter les fuites de mémoire ***
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // *** CORRECTION 4 : On implémente la méthode qui réagit aux changements de cycle de vie ***
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si l'application revient en avant-plan (après avoir quitté le navigateur pour Stripe)...
    if (state == AppLifecycleState.resumed) {
      final user = context.read<AuthenticationBloc>().state.user;
      // ...et si l'utilisateur est un formateur...
      if (user.role == UserRole.instructor && mounted) {
        // ...on relance la vérification du statut Stripe pour rafraîchir l'interface.
        context.read<StripeBloc>().add(
          FetchStripeAccountStatus(userId: user.id),
        );
      }
    }
  }

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()),
        BlocProvider(
          create: (context) {
            final user = context.read<AuthenticationBloc>().state.user;
            // On lance la vérification du statut dès la création du BLoC
            if (user.role == UserRole.instructor) {
              return sl<StripeBloc>()
                ..add(FetchStripeAccountStatus(userId: user.id));
            }
            return sl<StripeBloc>();
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Modifier le Profil' : 'Profil'),
          actions: [
            BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, authState) {
                if (authState.user.isNotEmpty) {
                  return IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
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
              setState(() {
                _isEditing = false;
                _imageFile = null;
              });
            }
          },
          builder: (context, profileUpdateState) {
            return BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, authState) {
                if (authState.user.isEmpty) {
                  return const Center(
                    child: Text('Vous n\'êtes pas connecté.'),
                  );
                }

                if (!_isEditing) {
                  _nameController.text = authState.user.name;
                  _emailController.text = authState.user.email;
                }

                return ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _buildAvatarImage(authState.user),
                            backgroundColor: Colors.grey.shade300,
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
                          ),
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
                    if (authState.user.role == UserRole.instructor) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        "Portefeuille Formateur",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStripeSection(context, authState.user),
                    ],
                    const SizedBox(height: 40),
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

  ImageProvider? _buildAvatarImage(User user) {
    if (_imageFile != null) {
      return FileImage(File(_imageFile!.path));
    }
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return NetworkImage(user.profileImageUrl!);
    }
    return null;
  }

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

  Widget _buildStripeSection(BuildContext context, User user) {
    return BlocConsumer<StripeBloc, StripeState>(
      listener: (context, state) {
        if (state is StripeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur Stripe: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is StripeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is StripeStatusLoaded) {
          final status = state.status;
          if (status.payoutsEnabled) {
            return const Card(
              color: Color(0xFF4CAF50),
              child: ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 30,
                ),
                title: Text(
                  "Votre compte est actif",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Vous pouvez recevoir des paiements.",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          }
          if (status.detailsSubmitted) {
            return const Card(
              color: Color(0xFFFB8C00),
              child: ListTile(
                leading: Icon(
                  Icons.hourglass_top,
                  color: Colors.white,
                  size: 30,
                ),
                title: Text(
                  "Vérification en cours",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Stripe vérifie vos informations.",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          }
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.credit_card,
                  size: 40,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Pour recevoir les paiements de vos élèves, vous devez configurer votre compte de paiement sécurisé avec Stripe.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text("Configurer les paiements"),
                  onPressed: () {
                    context.read<StripeBloc>().add(
                      CreateStripeConnectAccount(
                        userId: user.id,
                        email: user.email,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
