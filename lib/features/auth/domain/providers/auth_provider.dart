/// Provider de Autenticación
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../entities/user.dart' as app;

/// Provider para el cliente de Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider para el repositorio de auth
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

/// Provider para el estado de autenticación
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Provider para el usuario actual
final currentUserProvider = FutureProvider<app.User?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final session = repo.currentUser;
  
  if (session == null) return null;
  
  // Cargar perfil para obtener el rol
  final profile = await repo.getProfile(session.id);
  return profile ?? session;
});

/// Notifier para manejar login/logout
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _repo.signIn(
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
      await _repo.signOut();
      _ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider para el notifier de auth
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});
