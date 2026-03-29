/// Pantalla de Cajas
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'box_provider.dart';
import '../domain/entities/box_entities.dart';
import '../../auth/domain/providers/auth_provider.dart';
import '../../auth/domain/entities/user.dart';

class BoxesScreen extends ConsumerWidget {
  const BoxesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cajas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final user = userAsync.value;
              if (user != null) {
                ref.read(boxNotifierProvider.notifier).loadCurrentBox(user.id);
              }
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No hay usuario'));
          }

          // Usar FutureProvider para cargar caja automáticamente
          final boxAsync = ref.watch(currentUserBoxProvider);

          return boxAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (box) => _buildContent(context, ref, user, box),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, User user, CashBoxEntity? box) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Estado de la caja
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mi Caja',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: box != null && box.isOpen 
                            ? Colors.green.withValues(alpha: 0.1) 
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        box != null && box.isOpen ? 'Abierta' : 'Cerrada',
                        style: TextStyle(
                          color: box != null && box.isOpen ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (box != null && box.isOpen) ...[
                  _buildInfoRow('Monto inicial', currencyFormat.format(box.initialAmount)),
                  const SizedBox(height: 8),
                  
                  // Obtener totales de movimientos
                  _buildTotalsSection(ref, box.id, currencyFormat),
                  
                  const SizedBox(height: 8),
                  _buildInfoRow('Monto actual', currencyFormat.format(box.currentAmount), isBold: true),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Botón para cerrar/rendir caja
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCloseBoxDialog(context, ref, box),
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Hacer Rendición'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ),
                  // Ver movimientos
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showMovements(context, ref, box.id),
                    icon: const Icon(Icons.history),
                    label: const Text('Ver Movimientos'),
                  ),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No tienes una caja abierta',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Solo admin puede abrir caja para sí mismo (o para otro)
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showOpenBoxDialog(context, ref, user.id),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Abrir Caja'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Información
        Card(
          color: Colors.blue.withValues(alpha: 0.1),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El admin abre la caja con un monto inicial. Los cobradores registran sus cobros y al final del día hacen la rendición.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, bool isGreen = false, bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color: isGreen ? Colors.green : isRed ? Colors.red : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection(WidgetRef ref, String boxId, NumberFormat currencyFormat) {
    final totalsAsync = ref.watch(boxTotalsProvider(boxId));

    return totalsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (totals) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Total cobros', '+${currencyFormat.format(totals.totalCobros)}', isGreen: true),
          const SizedBox(height: 4),
          _buildInfoRow('Total egresos', '-${currencyFormat.format(totals.totalEgresos)}', isRed: true),
        ],
      ),
    );
  }

  Future<void> _showOpenBoxDialog(BuildContext context, WidgetRef ref, String userId) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese el monto inicial de la caja:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Monto inicial',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final amount = double.tryParse(controller.text) ?? 0;
      if (amount > 0) {
        final success = await ref.read(boxNotifierProvider.notifier).openBox(userId, amount);
        if (success && context.mounted) {
          // Invalidar provider para refrescar
          ref.invalidate(currentUserBoxProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Caja abierta correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al abrir caja'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    controller.dispose();
  }

  Future<void> _showCloseBoxDialog(BuildContext context, WidgetRef ref, CashBoxEntity box) async {
    final controller = TextEditingController(
      text: box.currentAmount.toStringAsFixed(2),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rendición de Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto inicial: \$${box.initialAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'Total cobrado: \$${box.totalCobrado.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Ingrese el monto total a rendición:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Monto rendición',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Rendir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final amount = double.tryParse(controller.text) ?? 0;
      if (amount > 0) {
        final success = await ref.read(boxNotifierProvider.notifier).closeBox(box.id, amount);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Rendición registrada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
    controller.dispose();
  }

  void _showMovements(BuildContext context, WidgetRef ref, String boxId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _MovementsSheet(
          boxId: boxId,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _MovementsSheet extends ConsumerWidget {
  final String boxId;
  final ScrollController scrollController;

  const _MovementsSheet({
    required this.boxId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(boxMovementsProvider(boxId));
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM HH:mm');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Movimientos de Caja',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (movements) {
                if (movements.isEmpty) {
                  return const Center(
                    child: Text('No hay movimientos'),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    return ListTile(
                      leading: Icon(
                        movement.type == MovementType.apertura
                            ? Icons.lock_open
                            : movement.type == MovementType.cobro
                                ? Icons.add_circle
                                : movement.type == MovementType.egreso
                                    ? Icons.remove_circle
                                    : Icons.assignment_turned_in,
                        color: movement.type == MovementType.cobro
                            ? Colors.green
                            : movement.type == MovementType.egreso
                                ? Colors.red
                                : Colors.purple,
                      ),
                      title: Text(_getMovementLabel(movement.type)),
                      subtitle: Text(
                        movement.description != null && movement.description!.isNotEmpty
                            ? '${movement.description} - ${dateFormat.format(movement.createdAt)}'
                            : dateFormat.format(movement.createdAt),
                      ),
                      trailing: Text(
                        '${movement.type == MovementType.egreso ? '-' : movement.type == MovementType.cobro ? '+' : ''}${currencyFormat.format(movement.amount.abs())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: movement.type == MovementType.cobro
                              ? Colors.green
                              : movement.type == MovementType.egreso
                                  ? Colors.red
                                  : Colors.black,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getMovementLabel(MovementType type) {
    switch (type) {
      case MovementType.apertura:
        return 'Apertura';
      case MovementType.cobro:
        return 'Cobro';
      case MovementType.egreso:
        return 'Egreso';
      case MovementType.rendicion:
        return 'Rendición';
      case MovementType.ajuste:
        return 'Ajuste';
    }
  }
}
