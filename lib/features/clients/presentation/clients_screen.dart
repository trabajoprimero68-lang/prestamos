/// Pantalla de Clientes
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../clients/domain/client_provider.dart';
import '../../clients/domain/entities/client_entity.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: clientsAsync.when(
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
                onPressed: () => ref.invalidate(clientNotifierProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (clients) {
          if (clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay clientes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agregá el primer cliente',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(clientNotifierProvider.notifier).loadClients();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return _ClientCard(client: client);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClientForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showClientForm(BuildContext context, WidgetRef ref, [ClientEntity? client]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ClientFormSheet(client: client),
    );
  }
}

class _ClientCard extends ConsumerWidget {
  final ClientEntity client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            client.nombre.isNotEmpty ? client.nombre[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(client.nombre),
        subtitle: Text(client.telefono ?? 'Sin teléfono'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => ClientFormSheet(client: client),
              );
            } else if (value == 'delete') {
              _confirmDelete(context, ref);
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Text('¿Estás seguro de eliminar a "${client.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(clientNotifierProvider.notifier).deactivateClient(client.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class ClientFormSheet extends ConsumerStatefulWidget {
  final ClientEntity? client;

  const ClientFormSheet({super.key, this.client});

  @override
  ConsumerState<ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends ConsumerState<ClientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  late TextEditingController _documentoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.client?.nombre ?? '');
    _telefonoController = TextEditingController(text: widget.client?.telefono ?? '');
    _direccionController = TextEditingController(text: widget.client?.direccion ?? '');
    _documentoController = TextEditingController(text: widget.client?.documento ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final notifier = ref.read(clientNotifierProvider.notifier);
    bool success;
    String? errorMessage;

    try {
      if (widget.client != null) {
        success = await notifier.updateClient(
          id: widget.client!.id,
          nombre: _nombreController.text,
          telefono: _telefonoController.text.isNotEmpty ? _telefonoController.text : null,
          direccion: _direccionController.text.isNotEmpty ? _direccionController.text : null,
          documento: _documentoController.text.isNotEmpty ? _documentoController.text : null,
        );
      } else {
        success = await notifier.createClient(
          nombre: _nombreController.text,
          telefono: _telefonoController.text.isNotEmpty ? _telefonoController.text : null,
          direccion: _direccionController.text.isNotEmpty ? _direccionController.text : null,
          documento: _documentoController.text.isNotEmpty ? _documentoController.text : null,
        );
      }
    } catch (e) {
      success = false;
      errorMessage = e.toString();
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.client != null ? 'Cliente actualizado' : 'Cliente creado'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Error al guardar cliente'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.client != null ? 'Editar Cliente' : 'Nuevo Cliente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentoController,
              decoration: const InputDecoration(
                labelText: 'Documento',
                prefixIcon: Icon(Icons.badge),
              ),
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
                  : Text(widget.client != null ? 'Guardar' : 'Crear Cliente'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
