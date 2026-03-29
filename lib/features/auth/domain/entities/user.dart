/// Entidad de Usuario
library;

import 'package:equatable/equatable.dart';

enum UserRole { admin, cobrador }

class User extends Equatable {
  final String id;
  final String email;
  final UserRole role;

  const User({
    required this.id,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isCobrador => role == UserRole.cobrador;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.cobrador,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role == UserRole.admin ? 'admin' : 'cobrador',
    };
  }

  @override
  List<Object?> get props => [id, email, role];
}
