/// Provider de Pagos/Cobros
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/payment_entities.dart';
import '../../auth/domain/providers/auth_provider.dart';

/// Provider para obtener configuración de mora
final moraConfigProvider = FutureProvider<double>((ref) async {
  final client = Supabase.instance.client;
  
  final response = await client
      .from('mora_config')
      .select()
      .eq('activo', true)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
  
  if (response == null) return 50.0; // Default
  return (response['monto'] as num).toDouble();
});

/// Provider para cuotas pendientes de hoy
final todayPaymentsProvider = FutureProvider<List<InstallmentEntity>>((ref) async {
  final client = Supabase.instance.client;
  final today = DateTime.now();
  final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  final response = await client
      .from('installments')
      .select('''
          *,
          loans!inner(
            clients!inner(nombre)
          )
        ''')
      .eq('estado', 'pendiente')
      .lte('fecha_vencimiento', dateStr)
      .order('fecha_vencimiento', ascending: true);
  
  return response.map((json) => _parseInstallment(json)).toList();
});

/// Provider para cuotas vencidas
final overduePaymentsProvider = FutureProvider<List<InstallmentEntity>>((ref) async {
  final client = Supabase.instance.client;
  final today = DateTime.now();
  final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  final response = await client
      .from('installments')
      .select('''
          *,
          loans!inner(
            clients!inner(nombre)
          )
        ''')
      .eq('estado', 'vencida')
      .order('fecha_vencimiento', ascending: true);
  
  return response.map((json) => _parseInstallment(json)).toList();
});

/// Helper para parsear installment
InstallmentEntity _parseInstallment(Map<String, dynamic> json) {
  return InstallmentEntity(
    id: json['id'] as String,
    loanId: json['loan_id'] as String,
    numeroCuota: json['numero_cuota'] as int,
    monto: (json['monto'] as num).toDouble(),
    montoPagado: (json['monto_pagado'] as num?)?.toDouble() ?? 0.0,
    moraAplicada: (json['mora_aplicada'] as num?)?.toDouble() ?? 0.0,
    fechaVencimiento: DateTime.parse(json['fecha_vencimiento'] as String),
    fechaPago: json['fecha_pago'] != null ? DateTime.parse(json['fecha_pago'] as String) : null,
    estado: json['estado'] as String,
  );
}

/// Notifier para operaciones de pago
class PaymentNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _client;
  final Ref _ref;

  PaymentNotifier(this._client, this._ref) : super(const AsyncValue.data(null));

  /// Calcular mora para una cuota
  Future<double> calculateMora(String installmentId) async {
    final moraPerDay = await _ref.read(moraConfigProvider.future);
    
    final installment = await _client
        .from('installments')
        .select()
        .eq('id', installmentId)
        .single();

    final fechaVencimiento = DateTime.parse(installment['fecha_vencimiento'] as String);
    final today = DateTime.now();
    final diasAtraso = today.difference(fechaVencimiento).inDays;

    if (diasAtraso <= 0) return 0;

    return moraPerDay * diasAtraso;
  }

  /// Registrar pago de cuota
  Future<bool> registerPayment({
    required String installmentId,
    required double montoCobrado,
    String? observaciones,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        state = AsyncValue.error('No hay usuario autenticado', StackTrace.current);
        return false;
      }

      // Calcular mora si hay atraso
      final mora = await calculateMora(installmentId);

      // Actualizar cuota
      await _client.from('installments').update({
        'monto_pagado': montoCobrado,
        'mora_aplicada': mora,
        'estado': 'pagada',
        'fecha_pago': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', installmentId);

      // Registrar intento de cobro
      await _client.from('payment_attempts').insert({
        'installment_id': installmentId,
        'cobrador_id': userId,
        'resultado': 'pagado',
        'monto_cobrado': montoCobrado,
        'mora_del_dia': mora,
        'observaciones': observaciones,
      });

      // Registrar cobro en la caja (si existe caja abierta)
      await _registerInBox(userId, montoCobrado, 'Cobro de cuota', installmentId);

      // Si hay mora, registrarla en la tabla de moras
      if (mora > 0) {
        try {
          final installment = await _client
              .from('installments')
              .select()
              .eq('id', installmentId)
              .maybeSingle();
          
          if (installment != null) {
            final fechaVencimiento = DateTime.parse(installment['fecha_vencimiento'] as String);
            final diasAtraso = DateTime.now().difference(fechaVencimiento).inDays;

            await _client.from('moras').insert({
              'installment_id': installmentId,
              'monto': mora,
              'dias_atraso': diasAtraso,
              'fecha_aplicacion': DateTime.now().toIso8601String().split('T')[0],
            });
          }
        } catch (e) {
          // Si falla el registro de mora, no importa, el pago ya se hizo
        }
      }

      // Verificar si el préstamo está completamente pagado
      try {
        await _checkLoanCompletion(installmentId);
      } catch (e) {
        // Si falla la verificación, no importa, el pago ya se registró
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Registrar un cobro en la caja del cobrador
  Future<void> _registerInBox(String userId, double amount, String description, String? installmentId) async {
    try {
      // Buscar caja abierta del usuario
      final box = await _client
          .from('cash_boxes')
          .select('id, current_amount')
          .eq('cobrador_id', userId)
          .eq('estado', 'abierta')
          .maybeSingle();

      if (box != null) {
        final boxId = box['id'] as String;
        final currentAmount = (box['current_amount'] as num).toDouble();
        final newAmount = currentAmount + amount;

        // Obtener nombre del cliente para el movimiento
        String clientName = '';
        if (installmentId != null) {
          try {
            final installment = await _client
                .from('installments')
                .select('loan_id')
                .eq('id', installmentId)
                .single();
            
            final loan = await _client
                .from('loans')
                .select('client_id')
                .eq('id', installment['loan_id'])
                .single();
            
            final client = await _client
                .from('clients')
                .select('nombre')
                .eq('id', loan['client_id'])
                .single();
            
            clientName = client['nombre'] as String? ?? '';
          } catch (e) {
            // Si falla, continúa sin nombre
          }
        }

        // Actualizar monto de la caja
        await _client.from('cash_boxes').update({
          'current_amount': newAmount,
        }).eq('id', boxId);

        // Registrar movimiento con nombre del cliente
        await _client.from('cash_box_movements').insert({
          'box_id': boxId,
          'type': 'cobro',
          'amount': amount,
          'description': clientName.isNotEmpty ? '$clientName - Cobro' : description,
        });
      }
    } catch (e) {
      // Si falla el registro en caja, no rompo el flujo del pago
      print('Error al registrar en caja: $e');
    }
  }

  /// Registrar no pago (pasa a lista del día siguiente)
  Future<bool> registerNoPayment({
    required String installmentId,
    String? observaciones,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Actualizar estado a vencida
      await _client.from('installments').update({
        'estado': 'vencida',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', installmentId);

      // Registrar intento
      await _client.from('payment_attempts').insert({
        'installment_id': installmentId,
        'cobrador_id': userId,
        'resultado': 'no_pagado',
        'observaciones': observaciones,
      });

      // Aplicar mora automáticamente por atraso
      await _applyMora(installmentId);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Diferir cobro al siguiente día (sin mora)
  Future<bool> deferPayment({
    required String installmentId,
    String? observaciones,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Obtener la cuota actual
      final installment = await _client
          .from('installments')
          .select('fecha_vencimiento')
          .eq('id', installmentId)
          .single();

      // Calcular nueva fecha de vencimiento (día siguiente)
      final fechaActual = DateTime.parse(installment['fecha_vencimiento'] as String);
      final nuevaFecha = fechaActual.add(const Duration(days: 1));
      final nuevaFechaStr = nuevaFecha.toIso8601String().split('T')[0];

      // Actualizar fecha de vencimiento al día siguiente
      await _client.from('installments').update({
        'fecha_vencimiento': nuevaFechaStr,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', installmentId);

      // Registrar intento de cobro diferido
      await _client.from('payment_attempts').insert({
        'installment_id': installmentId,
        'cobrador_id': userId,
        'resultado': 'diferir',
        'observaciones': observaciones ?? 'Diferido al siguiente día',
      });

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Aplicar mora automáticamente
  Future<void> _applyMora(String installmentId) async {
    final moraPerDay = await _ref.read(moraConfigProvider.future);
    
    final installment = await _client
        .from('installments')
        .select()
        .eq('id', installmentId)
        .single();

    final fechaVencimiento = DateTime.parse(installment['fecha_vencimiento'] as String);
    final diasAtraso = DateTime.now().difference(fechaVencimiento).inDays;

    if (diasAtraso > 0) {
      final mora = moraPerDay * diasAtraso;
      
      // Actualizar mora en cuota
      await _client.from('installments').update({
        'mora_aplicada': mora,
      }).eq('id', installmentId);

      // Registrar mora
      await _client.from('moras').insert({
        'installment_id': installmentId,
        'monto': mora,
        'dias_atraso': diasAtraso,
        'fecha_aplicacion': DateTime.now().toIso8601String().split('T')[0],
      });
    }
  }

  /// Verificar si el préstamo está completamente pagado
  Future<void> _checkLoanCompletion(String installmentId) async {
    // Obtener el loan_id de la cuota
    final installmentResult = await _client
        .from('installments')
        .select('loan_id')
        .eq('id', installmentId)
        .maybeSingle();

    if (installmentResult == null) return;
    
    final loanId = installmentResult['loan_id'] as String;

    // Verificar si hay cuotas pendientes (exclude la que acabamos de pagar)
    final pending = await _client
        .from('installments')
        .select('id')
        .eq('loan_id', loanId)
        .eq('estado', 'pendiente')
        .neq('id', installmentId)
        .maybeSingle();

    if (pending == null) {
      // Todas las cuotas pagadas, actualizar estado del préstamo
      await _client.from('loans').update({
        'estado': 'pagado',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', loanId);
    }
  }
}

/// Provider para el notifier de pagos
final paymentNotifierProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<void>>((ref) {
  final client = Supabase.instance.client;
  return PaymentNotifier(client, ref);
});

/// Entidad temporal para el provider
class InstallmentEntity {
  final String id;
  final String loanId;
  final int numeroCuota;
  final double monto;
  final double montoPagado;
  final double moraAplicada;
  final DateTime fechaVencimiento;
  final DateTime? fechaPago;
  final String estado;

  InstallmentEntity({
    required this.id,
    required this.loanId,
    required this.numeroCuota,
    required this.monto,
    required this.montoPagado,
    required this.moraAplicada,
    required this.fechaVencimiento,
    this.fechaPago,
    required this.estado,
  });

  double get totalAPagar => monto + moraAplicada;
  double get pendiente => totalAPagar - montoPagado;
}
