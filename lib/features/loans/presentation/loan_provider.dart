/// Provider de Préstamos
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/loan_entities.dart';
import '../../auth/domain/providers/auth_provider.dart';

/// Provider para obtener préstamos por estado
final loansByStatusProvider = FutureProvider.family<List<LoanEntity>, String>((ref, status) async {
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('loans')
      .select('''
          *,
          clients!inner(nombre)
        ''')
      .eq('estado', status)
      .order('created_at', ascending: false);
  
  return response.map((json) => LoanEntity.fromJson(json)).toList();
});

/// Provider para préstamos a entregar
final loansToDeliverProvider = FutureProvider<List<LoanEntity>>((ref) async {
  return ref.watch(loansByStatusProvider('a_entregar').future);
});

/// Provider para préstamos activos
final activeLoansProvider = FutureProvider<List<LoanEntity>>((ref) async {
  return ref.watch(loansByStatusProvider('activo').future);
});

/// Provider para cuotas de un préstamo
final installmentsProvider = FutureProvider.family<List<InstallmentEntity>, String>((ref, loanId) async {
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('installments')
      .select()
      .eq('loan_id', loanId)
      .order('numero_cuota', ascending: true);
  
  return response.map((json) => InstallmentEntity.fromJson(json)).toList();
});

/// Notifier para operaciones de préstamos
class LoanNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _client;
  final Ref _ref;

  LoanNotifier(this._client, this._ref) : super(const AsyncValue.data(null));

  /// Crear un nuevo préstamo y generar cuotas automáticamente
  Future<bool> createLoan({
    required String clientId,
    required double monto,
    required double interes,
    required int cantidadCuotas,
    required DateTime fechaInicio,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      // Calcular monto de cuota
      final montoTotal = monto + (monto * interes / 100);
      final montoCuota = montoTotal / cantidadCuotas;

      // Crear préstamo
      final loanResponse = await _client.from('loans').insert({
        'client_id': clientId,
        'monto': monto,
        'interes': interes,
        'cantidad_cuotas': cantidadCuotas,
        'monto_cuota': montoCuota,
        'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
        'estado': 'a_entregar',
      }).select().single();

      // Generar cuotas
      final installments = <Map<String, dynamic>>[];
      for (int i = 1; i <= cantidadCuotas; i++) {
        final fechaVencimiento = fechaInicio.add(Duration(days: 30 * (i - 1)));
        installments.add({
          'loan_id': loanResponse['id'],
          'numero_cuota': i,
          'monto': montoCuota,
          'monto_pagado': 0,
          'mora_aplicada': 0,
          'fecha_vencimiento': fechaVencimiento.toIso8601String().split('T')[0],
          'estado': 'pendiente',
        });
      }

      await _client.from('installments').insert(installments);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Entregar préstamo (cambiar estado de a_entregar a activo)
  Future<bool> deliverLoan(String loanId) async {
    state = const AsyncValue.loading();
    
    try {
      await _client.from('loans').update({
        'estado': 'activo',
        'fecha_entrega': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', loanId);

      // Registrar intento de entrega
      await _client.from('delivery_attempts').insert({
        'loan_id': loanId,
        'cobrador_id': _client.auth.currentUser?.id,
        'resultado': 'entregado',
      });

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reprogramar fecha de entrega
  Future<bool> rescheduleDelivery(String loanId, DateTime newDate) async {
    try {
      await _client.from('loans').update({
        'fecha_entrega': newDate.toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', loanId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pasar entrega al siguiente día (sin mora)
  Future<bool> deferDelivery(String loanId) async {
    try {
      final loan = await _client
          .from('loans')
          .select()
          .eq('id', loanId)
          .single();

      final fechaEntrega = loan['fecha_entrega'] != null
          ? DateTime.parse(loan['fecha_entrega'] as String)
          : DateTime.parse(loan['fecha_inicio'] as String);

      final newDate = fechaEntrega.add(const Duration(days: 1));

      await _client.from('loans').update({
        'fecha_entrega': newDate.toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', loanId);

      // Registrar intento
      await _client.from('delivery_attempts').insert({
        'loan_id': loanId,
        'cobrador_id': _client.auth.currentUser?.id,
        'resultado': 'diferir',
        'observaciones': 'Diferido al siguiente día',
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider para el notifier de préstamos
final loanNotifierProvider = StateNotifierProvider<LoanNotifier, AsyncValue<void>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return LoanNotifier(client, ref);
});
