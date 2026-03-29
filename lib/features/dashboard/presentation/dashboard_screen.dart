/// Pantalla del Dashboard - 4 listas operativas
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/entities/dashboard_data.dart';
import '../../auth/domain/providers/auth_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ALE Gestión'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
        },
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (dashboard) => _buildContent(context, ref, dashboard),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickActions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardData dashboard) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Saludo
        _buildHeader(context),
        const SizedBox(height: 24),

        // Lista 1: Préstamos a ENTREGAR
        _buildSection(
          context,
          title: 'A ENTREGAR',
          icon: Icons.delivery_dining,
          color: Colors.blue,
          count: dashboard.aEntregar.length,
          emptyMessage: 'No hay préstamos pendientes de entrega',
          onTap: () => context.go('/loans'),
        ),
        const SizedBox(height: 16),

        // Lista 2: Préstamos a COBRAR
        _buildSection(
          context,
          title: 'A COBRAR',
          icon: Icons.payments,
          color: Colors.green,
          count: dashboard.aCobrar.length,
          emptyMessage: 'No hay cuotas para cobrar hoy',
          onTap: () => context.go('/payments'),
        ),
        const SizedBox(height: 16),

        // Lista 3: PENDIENTES (no pagados ayer)
        _buildSection(
          context,
          title: 'PENDIENTES',
          icon: Icons.pending_actions,
          color: Colors.orange,
          count: dashboard.pendientes.length,
          emptyMessage: 'No hay cobros pendientes',
          onTap: () => context.go('/payments'),
        ),
        const SizedBox(height: 16),

        // Lista 4: CAJA
        _buildBoxSection(
          context,
          box: dashboard.caja,
          currencyFormat: currencyFormat,
          onTap: () => context.go('/boxes'),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateStr = DateFormat('d/MM/yyyy').format(now);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Resumen del día $dateStr',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required String emptyMessage,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count > 0 ? '$count elemento${count == 1 ? '' : 's'}' : emptyMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: count > 0 ? color : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxSection(
    BuildContext context, {
    required CashBox? box,
    required NumberFormat currencyFormat,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.purple, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAJA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      box != null
                          ? 'Monto actual: ${currencyFormat.format(box.currentAmount)}'
                          : 'No hay caja abierta',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: box != null ? Colors.purple : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Nuevo Cliente'),
              onTap: () {
                Navigator.pop(context);
                context.go('/clients');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_card),
              title: const Text('Nuevo Préstamo'),
              onTap: () {
                Navigator.pop(context);
                context.go('/loans');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('Registrar Cobro'),
              onTap: () {
                Navigator.pop(context);
                context.go('/payments');
              },
            ),
          ],
        ),
      ),
    );
  }
}
