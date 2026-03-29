/// Provider del Dashboard
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/dashboard_data.dart';
import '../../auth/domain/providers/auth_provider.dart';

/// Provider para obtener préstamos a entregar
final pendingDeliveriesProvider = FutureProvider<List<Loan>>((ref) async {
  final client = Supabase.instance.client;
   
  final response = await client
      .from('loans')
      .select('''
          *,
          clients!inner(nombre)
        ''')
      .eq('estado', 'a_entregar')
      .order('fecha_inicio', ascending: true);
  
  return response.map((json) => Loan.fromJson(json)).toList();
});

/// Provider para obtener cuotas a cobrar hoy
final todayInstallmentsProvider = FutureProvider<List<Installment>>((ref) async {
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
  
  return response.map((json) => Installment.fromJson(json)).toList();
});

/// Provider para obtener cuotas pendientes (atrasadas)
final overdueInstallmentsProvider = FutureProvider<List<Installment>>((ref) async {
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
  
  return response.map((json) => Installment.fromJson(json)).toList();
});

/// Provider para obtener la caja actual del cobrador
final currentBoxProvider = FutureProvider<CashBox?>((ref) async {
  final client = Supabase.instance.client;
  final user = ref.watch(currentUserProvider);
  
  final userValue = user.valueOrNull;
  if (userValue == null) return null;
  
  final response = await client
      .from('cash_boxes')
      .select()
      .eq('cobrador_id', userValue.id)
      .eq('estado', 'abierta')
      .maybeSingle();
  
  if (response == null) return null;
  return CashBox.fromJson(response);
});

/// Provider principal del Dashboard
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final deliveries = await ref.watch(pendingDeliveriesProvider.future);
  final todayDue = await ref.watch(todayInstallmentsProvider.future);
  final overdue = await ref.watch(overdueInstallmentsProvider.future);
  final box = await ref.watch(currentBoxProvider.future);
  
  return DashboardData(
    aEntregar: deliveries,
    aCobrar: todayDue,
    pendientes: overdue,
    caja: box,
  );
});

/// Provider para recargar el dashboard
final refreshDashboardProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(dashboardProvider);
    ref.invalidate(pendingDeliveriesProvider);
    ref.invalidate(todayInstallmentsProvider);
    ref.invalidate(overdueInstallmentsProvider);
    ref.invalidate(currentBoxProvider);
  };
});
