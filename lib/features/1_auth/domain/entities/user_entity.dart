import 'package:equatable/equatable.dart';

// Représente un utilisateur authentifié dans l'application.
class User extends Equatable {
  final String id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  // Un constructeur "vide" pour représenter un utilisateur non authentifié.
  static const empty = User(id: '', name: '', email: '');

  // Permet de savoir facilement si l'objet User est vide ou non.
  bool get isEmpty => this == User.empty;
  bool get isNotEmpty => this != User.empty;

  @override
  List<Object?> get props => [id, name, email];
}
