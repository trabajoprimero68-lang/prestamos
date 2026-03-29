/// Provider de Cajas
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/box_entities.dart';
import '../../auth/domain/providers/auth_provider.dart';

/// Provider para abrir una caja (solo admin)
final openBoxProvider = FutureProvider.family<CashBoxEntity?, String>((ref, cobradorId) async {
  final client = Supabase.instance.client;
   
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
  final client = Supabase.instance.client;
  return BoxNotifier(client, ref);
});

/// Provider para obtener la caja actual del usuario logueado
final currentUserBoxProvider = FutureProvider<CashBoxEntity?>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  
  if (user == null) return null;
  
  final response = await client
      .from('cash_boxes')
      .select()
      .eq('cobrador_id', user.id)
      .eq('estado', 'abierta')
      .maybeSingle();

  if (response == null) return null;
  return CashBoxEntity.fromJson(response);
});

/// Provider para movimientos de caja
final boxMovementsProvider = FutureProvider.family<List<CashBoxMovement>, String>((ref, boxId) async {
  final client = Supabase.instance.client;
   
  // Obtener movimientos
  final movements = await client
      .from('cash_box_movements')
      .select()
      .eq('box_id', boxId)
      .order('created_at', ascending: false);
  
  // Para cada movimiento, obtener más detalles
  final List<CashBoxMovement> result = [];
  
  for (final movement in movements) {
    final type = movement['type'] as String;
    String? description = movement['description'] as String?;
    String? reference = '';
    
    if (type == 'cobro' && description != null && description.contains('Cobro de cuota')) {
      // Buscar el payment_attempt para obtener info del cliente
      try {
        final attempts = await client
            .from('payment_attempts')
            .select('''
              installments!inner(
                loans!inner(
                  clients!inner(nombre)
                ),
                numero_cuota
              )
            ''')
            .eq('resultado', 'pagado')
            .eq('monto_cobrado', double.tryParse(description.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0)
            .order('created_at', ascending: false)
            .limit(1);
        
        if (attempts.isNotEmpty) {
          final attempt = attempts.first;
          final cliente = attempt['installments']['loans']['clients']['nombre'] as String?;
          final cuota = attempt['installments']['numero_cuota'] as int?;
          if (cliente != null) {
            reference = '$cliente - Cuota #$cuota';
          }
        }
      } catch (e) {
        // Si falla, usar la descripción original
        reference = description;
      }
    } else if (type == 'egreso' && description != null && description.contains('Entrega de préstamo')) {
      // Buscar el delivery_attempt para obtener info del cliente
      try {
        final deliveries = await client
            .from('delivery_attempts')
            .select('''
              loans!inner(
                clients!inner(nombre)
              ),
              loans!inner(monto)
            ''')
            .eq('resultado', 'entregado')
            .order('created_at', ascending: false)
            .limit(1);
        
        if (deliveries.isNotEmpty) {
          final delivery = deliveries.first;
          final cliente = delivery['loans']['clients']['nombre'] as String?;
          final monto = delivery['loans']['monto'] as double?;
          if (cliente != null) {
            reference = '$cliente - \$${monto?.toStringAsFixed(2)}';
          }
        }
      } catch (e) {
        reference = description;
      }
    }
    
    result.add(CashBoxMovement.fromJson(movement, reference: reference));
  }
  
  return result;
});

/// Provider para totales de caja
final boxTotalsProvider = FutureProvider.family<BoxTotals, String>((ref, boxId) async {
  final client = Supabase.instance.client;
   
  final response = await client
      .from('cash_box_movements')
      .select('type, amount')
      .eq('box_id', boxId);
  
  double totalCobros = 0;
  double totalEgresos = 0;
  
  for (final row in response) {
    final type = row['type'] as String;
    final amount = (row['amount'] as num).toDouble();
    
    if (type == 'cobro') {
      totalCobros += amount;
    } else if (type == 'egreso') {
      totalEgresos += amount.abs();
    }
  }
  
  return BoxTotals(totalCobros: totalCobros, totalEgresos: totalEgresos);
});

/// Clase para totales de caja
class BoxTotals {
  final double totalCobros;
  final double totalEgresos;
  
  BoxTotals({required this.totalCobros, required this.totalEgresos});
}
