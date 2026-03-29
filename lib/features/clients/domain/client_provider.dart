/// Provider de Clientes
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/client_entity.dart';

/// Provider para obtener todos los clientes activos
final clientsProvider = FutureProvider<List<ClientEntity>>((ref) async {
  final client = Supabase.instance.client;
  
  final response = await client
      .from('clients')
      .select()
      .eq('estado', 'activo')
      .order('nombre', ascending: true);
  
  return response.map((json) => ClientEntity.fromJson(json)).toList();
});

/// Provider para obtener un cliente específico
final clientProvider = FutureProvider.family<ClientEntity?, String>((ref, id) async {
  final client = Supabase.instance.client;
  
  final response = await client
      .from('clients')
      .select()
      .eq('id', id)
      .maybeSingle();
  
  if (response == null) return null;
  return ClientEntity.fromJson(response);
});

/// Notifier para operaciones de clientes
class ClientNotifier extends StateNotifier<AsyncValue<List<ClientEntity>>> {
  final SupabaseClient _client;

  ClientNotifier(this._client) : super(const AsyncValue.data([])) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _client
          .from('clients')
          .select()
          .eq('estado', 'activo')
          .order('nombre', ascending: true);
      
      state = AsyncValue.data(response.map((json) => ClientEntity.fromJson(json)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createClient({
    required String nombre,
    String? telefono,
    String? direccion,
    String? documento,
  }) async {
    try {
      await _client.from('clients').insert({
        'nombre': nombre,
        'telefono': telefono,
        'direccion': direccion,
        'documento': documento,
        'estado': 'activo',
      });
      
      await loadClients();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateClient({
    required String id,
    required String nombre,
    String? telefono,
    String? direccion,
    String? documento,
  }) async {
    try {
      await _client.from('clients').update({
        'nombre': nombre,
        'telefono': telefono,
        'direccion': direccion,
        'documento': documento,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      
      await loadClients();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deactivateClient(String id) async {
    try {
      await _client.from('clients').update({
        'estado': 'inactivo',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      
      await loadClients();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider para el notifier de clientes
final clientNotifierProvider = StateNotifierProvider<ClientNotifier, AsyncValue<List<ClientEntity>>>((ref) {
  final client = Supabase.instance.client;
  return ClientNotifier(client);
});
