/// Pantalla de Préstamos
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../loans/presentation/loan_provider.dart';
import '../../loans/domain/entities/loan_entities.dart';
import '../../clients/domain/client_provider.dart';
import '../../clients/domain/entities/client_entity.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  int _refreshCounter = 0;

  @override
  Widget build(BuildContext context) {
    // Forzar rebuild cuando cambia el counter
    if (_refreshCounter > 0) {
      _refreshCounter--;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préstamos'),
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
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'A Entregar'),
                Tab(text: 'Activos'),
                Tab(text: 'Pagados'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _LoansList(status: 'a_entregar'),
                  _LoansList(status: 'activo'),
                  _LoansList(status: 'pagado'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLoanForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _refreshData() {
    ref.invalidate(loansToDeliverProvider);
    ref.invalidate(activeLoansProvider);
    ref.invalidate(loansByStatusProvider('pagado'));
    setState(() {
      _refreshCounter++;
    });
  }

  void _showLoanForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LoanFormSheet(),
    );
    // Recargar datos al cerrar el formulario
    _refreshData();
  }
}

class _LoansList extends ConsumerWidget {
  final String status;

  const _LoansList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usar el provider correcto según el status
    final loansAsync = status == 'a_entregar'
        ? ref.watch(loansToDeliverProvider)
        : status == 'activo'
            ? ref.watch(activeLoansProvider)
            : ref.watch(loansByStatusProvider('pagado'));

    // Función para refresh según el tab
    Future<void> _refresh() async {
      if (status == 'a_entregar') {
        ref.invalidate(loansToDeliverProvider);
      } else if (status == 'activo') {
        ref.invalidate(activeLoansProvider);
      } else {
        ref.invalidate(loansByStatusProvider('pagado'));
      }
      // Esperar un poco para que se actualice
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return loansAsync.when(
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
      data: (loans) => RefreshIndicator(
        onRefresh: _refresh,
        child: loans.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            status == 'a_entregar' ? Icons.delivery_dining :
                            status == 'activo' ? Icons.account_balance : Icons.check_circle,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            status == 'a_entregar' ? 'No hay préstamos por entregar' :
                            status == 'activo' ? 'No hay préstamos activos' : 'No hay préstamos pagados',
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
                itemCount: loans.length,
                itemBuilder: (context, index) {
                  return _LoanCard(loan: loans[index]);
                },
              ),
      ),
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final LoanEntity loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    Color statusColor;
    String statusText;
    switch (loan.estado) {
      case LoanStatus.aEntregar:
        statusColor = Colors.blue;
        statusText = 'Por entregar';
        break;
      case LoanStatus.activo:
        statusColor = Colors.green;
        statusText = 'Activo';
        break;
      case LoanStatus.mora:
        statusColor = Colors.red;
        statusText = 'En mora';
        break;
      case LoanStatus.pagado:
        statusColor = Colors.grey;
        statusText = 'Pagado';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showLoanDetails(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loan.clientNombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
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
                    currencyFormat.format(loan.monto),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    // Mostrar fecha de entrega si existe, si no fecha de inicio
                    loan.fechaEntrega != null
                        ? 'Entrega: ${dateFormat.format(loan.fechaEntrega!)}'
                        : 'Inicio: ${dateFormat.format(loan.fechaInicio)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${loan.cantidadCuotas} cuotas de ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    currencyFormat.format(loan.montoCuota),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (loan.estado == LoanStatus.aEntregar) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rescheduleDelivery(context, ref),
                        child: const Text(' reprogramar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _deliverLoan(context, ref),
                        child: const Text('Entregar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLoanDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LoanDetailSheet(loan: loan),
    );
  }

  Future<void> _deliverLoan(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Text('¿Marcar préstamo de ${loan.clientNombre} como entregado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Entregar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(loanNotifierProvider.notifier).deliverLoan(loan.id);
      
      if (success) {
        // Refrescar datos
        ref.invalidate(loansToDeliverProvider);
        ref.invalidate(activeLoansProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préstamo entregado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al entregar préstamo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleDelivery(BuildContext context, WidgetRef ref) async {
    // Mostrar date picker
    final newDate = await showDatePicker(
      context: context,
      initialDate: loan.fechaEntrega ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (newDate == null) return;

    // Ejecutar la actualización
    final result = await ref.read(loanNotifierProvider.notifier).rescheduleDelivery(loan.id, newDate);
    
    // Ver el estado del provider después de la operación
    final providerState = ref.read(loanNotifierProvider);
    
    if (result) {
      // Refrescar datos
      ref.invalidate(loansToDeliverProvider);
      ref.invalidate(activeLoansProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fecha reprogramada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Mostrar error detallado
      String errorMsg = '❌ Error al reprogramar';
      if (providerState.hasError) {
        errorMsg = 'Error: ${providerState.error}';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

class LoanFormSheet extends ConsumerStatefulWidget {
  const LoanFormSheet({super.key});

  @override
  ConsumerState<LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends ConsumerState<LoanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  ClientEntity? _selectedClient;
  final _montoController = TextEditingController();
  final _interesController = TextEditingController(text: '0');
  final _cuotasController = TextEditingController(text: '1');
  DateTime _fechaInicio = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _montoController.dispose();
    _interesController.dispose();
    _cuotasController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un cliente')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(loanNotifierProvider.notifier).createLoan(
      clientId: _selectedClient!.id,
      monto: double.parse(_montoController.text),
      interes: double.parse(_interesController.text),
      cantidadCuotas: int.parse(_cuotasController.text),
      fechaInicio: _fechaInicio,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Refrescar las listas
      ref.invalidate(loansToDeliverProvider);
      ref.invalidate(activeLoansProvider);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo creado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear préstamo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientNotifierProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nuevo Préstamo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Selector de cliente
              clientsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error al cargar clientes'),
                data: (clients) => DropdownButtonFormField<ClientEntity>(
                  decoration: const InputDecoration(
                    labelText: 'Cliente *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  value: _selectedClient,
                  items: clients.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.nombre),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedClient = value),
                  validator: (value) => value == null ? 'Seleccione un cliente' : null,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese el monto';
                  if (double.tryParse(value) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _interesController,
                      decoration: const InputDecoration(
                        labelText: 'Interés %',
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cuotasController,
                      decoration: const InputDecoration(
                        labelText: 'Cuotas *',
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requerido';
                        if (int.tryParse(value) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de inicio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaInicio)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _fechaInicio,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() => _fechaInicio = date);
                  }
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear Préstamo'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class LoanDetailSheet extends ConsumerWidget {
  final LoanEntity loan;

  const LoanDetailSheet({super.key, required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installmentsAsync = ref.watch(installmentsProvider(loan.id));
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
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
              loan.clientNombre,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Monto: ${currencyFormat.format(loan.monto)}'),
            Text('Interés: ${loan.interes}%'),
            Text('Cuotas: ${loan.cantidadCuotas}'),
            Text('Fecha inicio: ${dateFormat.format(loan.fechaInicio)}'),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Cuotas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: installmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (installments) => ListView.builder(
                  controller: scrollController,
                  itemCount: installments.length,
                  itemBuilder: (context, index) {
                    final inst = installments[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: inst.isPaid ? Colors.green : Colors.orange,
                        child: Text(
                          '${inst.numeroCuota}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(currencyFormat.format(inst.monto)),
                      subtitle: Text('Vence: ${dateFormat.format(inst.fechaVencimiento)}'),
                      trailing: inst.isPaid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Text(currencyFormat.format(inst.moraAplicada)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
