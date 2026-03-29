/// Pantalla de Cobros/Pagos
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'payment_provider.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  int _refreshCounter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Hoy'),
                Tab(text: 'Vencidas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _InstallmentsList(isOverdue: false),
                  _InstallmentsList(isOverdue: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshData() {
    ref.invalidate(todayPaymentsProvider);
    ref.invalidate(overduePaymentsProvider);
    setState(() {
      _refreshCounter++;
    });
  }
}

class _InstallmentsList extends ConsumerWidget {
  final bool isOverdue;

  const _InstallmentsList({required this.isOverdue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installmentsAsync = isOverdue
        ? ref.watch(overduePaymentsProvider)
        : ref.watch(todayPaymentsProvider);

    Future<void> _refresh() async {
      if (isOverdue) {
        ref.invalidate(overduePaymentsProvider);
      } else {
        ref.invalidate(todayPaymentsProvider);
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return installmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (installments) => RefreshIndicator(
        onRefresh: _refresh,
        child: installments.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOverdue ? Icons.check_circle : Icons.calendar_today,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isOverdue
                                ? 'No hay cuotas vencidas'
                                : 'No hay cuotas para hoy',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: installments.length,
                itemBuilder: (context, index) {
                  return _InstallmentCard(
                    installment: installments[index],
                    isOverdue: isOverdue,
                  );
                },
              ),
      ),
    );
  }
}

class _InstallmentCard extends ConsumerWidget {
  final InstallmentEntity installment;
  final bool isOverdue;

  const _InstallmentCard({
    required this.installment,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Calcular mora automáticamente
    final diasAtraso = DateTime.now().difference(installment.fechaVencimiento).inDays;
    final mora = diasAtraso > 0 ? diasAtraso * 50.0 : 0.0; // 50 es el default
    final totalAPagar = installment.monto + mora;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cuota #${installment.numeroCuota}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOverdue ? Colors.red : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOverdue ? 'Vencida' : 'Pendiente',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  currencyFormat.format(installment.monto),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Vence: ${dateFormat.format(installment.fechaVencimiento)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (diasAtraso > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '($diasAtraso días)',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            if (mora > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Mora: ${currencyFormat.format(mora)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Total a pagar: ${currencyFormat.format(totalAPagar)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDeferDialog(context, ref),
                    child: const Text('Diferir'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showNoPayDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                    child: const Text('No pagó'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showPaymentDialog(context, ref, mora),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, WidgetRef ref, double mora) async {
    final controller = TextEditingController(
      text: (installment.monto + mora).toStringAsFixed(2),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuota #${installment.numeroCuota}'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Monto cobrado',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final monto = double.tryParse(controller.text) ?? installment.monto;
      
      final success = await ref.read(paymentNotifierProvider.notifier).registerPayment(
        installmentId: installment.id,
        montoCobrado: monto,
      );

      if (success) {
        ref.invalidate(todayPaymentsProvider);
        ref.invalidate(overduePaymentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Pago registrado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al registrar pago'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    controller.dispose();
  }

  Future<void> _showNoPayDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No pagó'),
        content: const Text('¿Confirmar que esta cuota no fue pagada? Se aplicará mora.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(paymentNotifierProvider.notifier).registerNoPayment(
        installmentId: installment.id,
      );

      if (success) {
        ref.invalidate(todayPaymentsProvider);
        ref.invalidate(overduePaymentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registrado como no pagado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeferDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diferir'),
        content: const Text('¿Diferir el cobro para mañana? No se aplicará mora.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(paymentNotifierProvider.notifier).deferPayment(
        installmentId: installment.id,
      );

      if (success) {
        ref.invalidate(todayPaymentsProvider);
        ref.invalidate(overduePaymentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Diferido para mañana'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    }
  }
}
