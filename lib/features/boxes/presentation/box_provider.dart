/// Provider de Cajas
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/box_entities.dart';
import '../../auth/domain/providers/auth_provider.dart';

/// Provider para abrir una caja (solo admin)
final openBoxProvider = FutureProvider.family<CashBoxEntity?, String>((ref, cobradorId) async {
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('cash_boxes')
      .select()
      .eq('cobrador_id', cobradorId)
      .eq('estado', 'abierta')
      .maybeSingle();
  
  if (response == null) return null;
  return CashBoxEntity.fromJson(response);
});

/// Notifier para operaciones de caja
class BoxNotifier extends StateNotifier<AsyncValue<CashBoxEntity?>> {
  final SupabaseClient _client;
  final Ref _ref;

  BoxNotifier(this._client, this._ref) : super(const AsyncValue.data(null));

  /// Abrir caja para un cobrador (admin hace esto)
  Future<bool> openBox(String cobradorId, double initialAmount) async {
    state = const AsyncValue.loading();
    
    try {
      // Verificar si ya tiene caja abierta
      final existing = await _client
          .from('cash_boxes')
          .select()
          .eq('cobrador_id', cobradorId)
          .eq('estado', 'abierta')
          .maybeSingle();
      
      if (existing != null) {
        state = AsyncValue.error('El cobrador ya tiene una caja abierta', StackTrace.current);
        return false;
      }

      // Crear caja
      final boxResponse = await _client.from('cash_boxes').insert({
        'cobrador_id': cobradorId,
        'initial_amount': initialAmount,
        'current_amount': initialAmount,
        'estado': 'abierta',
      }).select().single();

      // Registrar movimiento de apertura
      await _client.from('cash_box_movements').insert({
        'box_id': boxResponse['id'],
        'type': 'apertura',
        'amount': initialAmount,
        'description': 'Apertura de caja',
      });

      state = AsyncValue.data(CashBoxEntity.fromJson(boxResponse));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Cerrar caja (rendición)
  Future<bool> closeBox(String boxId, double amountCollected) async {
    state = const AsyncValue.loading();
    
    try {
      final box = await _client
          .from('cash_boxes')
          .select()
          .eq('id', boxId)
          .single();

      // Actualizar caja
      await _client.from('cash_boxes').update({
        'current_amount': amountCollected,
        'estado': 'cerrada',
        'closed_at': DateTime.now().toIso8601String(),
      }).eq('id', boxId);

      // Registrar movimiento de rendición
      await _client.from('cash_box_movements').insert({
        'box_id': boxId,
        'type': 'rendicion',
        'amount': amountCollected,
        'description': 'Rendición de caja',
      });

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Registrar cobro en caja
  Future<bool> registerCollection(String boxId, double amount) async {
    try {
      // Obtener caja actual
      final box = await _client
          .from('cash_boxes')
          .select()
          .eq('id', boxId)
          .single();

      final newAmount = (box['current_amount'] as num).toDouble() + amount;

      // Actualizar monto
      await _client.from('cash_boxes').update({
        'current_amount': newAmount,
      }).eq('id', boxId);

      // Registrar movimiento
      await _client.from('cash_box_movements').insert({
        'box_id': boxId,
        'type': 'cobro',
        'amount': amount,
        'description': 'Cobro registrado',
      });

      // Recargar estado
      final updatedBox = await _client
          .from('cash_boxes')
          .select()
          .eq('id', boxId)
          .single();

      state = AsyncValue.data(CashBoxEntity.fromJson(updatedBox));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Obtener caja actual del usuario
  Future<void> loadCurrentBox(String userId) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _client
          .from('cash_boxes')
          .select()
          .eq('cobrador_id', userId)
          .eq('estado', 'abierta')
          .maybeSingle();

      if (response != null) {
        state = AsyncValue.data(CashBoxEntity.fromJson(response));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider para el notifier de cajas
final boxNotifierProvider = StateNotifierProvider<BoxNotifier, AsyncValue<CashBoxEntity?>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BoxNotifier(client, ref);
});

/// Provider para movimientos de caja
final boxMovementsProvider = FutureProvider.family<List<CashBoxMovement>, String>((ref, boxId) async {
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('cash_box_movements')
      .select()
      .eq('box_id', boxId)
      .order('created_at', ascending: false);
  
  return response.map((json) => CashBoxMovement.fromJson(json)).toList();
});
