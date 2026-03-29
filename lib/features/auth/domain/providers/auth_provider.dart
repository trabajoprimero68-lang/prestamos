/// Provider de Autenticación
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../entities/user.dart' as app;

/// Provider para el cliente de Supabase - se ejecuta lazily
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  // Usar Supabase.instance solo cuando se necesita
  return Supabase.instance.client;
});

/// Provider para el repositorio de auth
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Obtener el cliente lazily
  final client = Supabase.instance.client;
  return AuthRepository(client);
});

/// Provider para el estado de autenticación
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange;
});

/// Provider para el usuario actual
final currentUserProvider = FutureProvider<app.User?>((ref) async {
  final client = Supabase.instance.client;
  final session = client.auth.currentSession;
  
  if (session == null) return null;
  
  // Cargar perfil para obtener el rol
  final profile = await client
      .from('profiles')
      .select()
      .eq('id', session.user.id)
      .maybeSingle();
  
  if (profile != null) {
    return app.User.fromJson(profile);
  }
  
  return app.User(
    id: session.user.id,
    email: session.user.email ?? '',
    role: app.UserRole.cobrador,
  );
});

/// Notifier para manejar login/logout
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _client;
  final Ref _ref;

  AuthNotifier(this._client, this._ref) : super(const AsyncValue.data(null));

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Invalidar providers para recargar datos
        _ref.invalidate(currentUserProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      
      state = AsyncValue.error('Error al iniciar sesión', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      await _client.auth.signOut();
      _ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider para el notifier de auth
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final client = Supabase.instance.client;
  return AuthNotifier(client, ref);
});
