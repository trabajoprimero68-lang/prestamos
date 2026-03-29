/// Cliente de Supabase
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseClientManager {
  SupabaseClientManager._();

  static SupabaseClient? _client;

  /// Inicializa el cliente de Supabase
  /// Debe llamarse antes de usar cualquier servicio de Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Obtiene la instancia del cliente
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase no ha sido inicializado. '
        'Llama a SupabaseClientManager.initialize() primero.',
      );
    }
    return _client!;
  }

  /// Obtiene el cliente usando las constantes por defecto
  static Future<void> initializeWithDefaults() async {
    await initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// Cierra la sesión actual
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
