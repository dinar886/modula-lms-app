import 'package:equatable/equatable.dart';

// On définit une énumération pour les rôles pour éviter les erreurs de frappe.
enum UserRole { learner, instructor, unknown }

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role; // On ajoute le rôle.

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  static const empty = User(
    id: '',
    name: '',
    email: '',
    role: UserRole.unknown,
  );

  bool get isEmpty => this == User.empty;
  bool get isNotEmpty => this != User.empty;

  @override
  List<Object?> get props => [id, name, email, role];
}
