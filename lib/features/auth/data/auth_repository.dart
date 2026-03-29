/// Repositorio de Autenticación
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/user.dart' as app;

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Obtiene el usuario actual
  app.User? get currentUser {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final user = session.user;
    // Por defecto, si no tiene perfil, es cobrador
    return app.User(
      id: user.id,
      email: user.email ?? '',
      role: app.UserRole.cobrador, // Se actualiza cuando carga el perfil
    );
  }

  /// Verifica si hay sesión activa
  bool get isLoggedIn => _client.auth.currentSession != null;

  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Obtener perfil del usuario
  Future<app.User?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    return app.User.fromJson(response);
  }

  /// Escuchar cambios en la autenticación
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
