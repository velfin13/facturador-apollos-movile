import 'package:flutter/material.dart';
import '../../domain/entities/cliente.dart';

class ClienteListWidget extends StatelessWidget {
  final List<Cliente> clientes;
  final bool hasMore;
  final int total;
  final VoidCallback? onLoadMore;

  const ClienteListWidget({
    super.key,
    required this.clientes,
    this.hasMore = false,
    this.total = 0,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (clientes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(child: Text('No hay clientes disponibles')),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            hasMore) {
          onLoadMore?.call();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: clientes.length + 2,
        itemBuilder: (context, index) {
          // Header con conteo
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
              child: Text(
                'Mostrando ${clientes.length} de $total clientes',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            );
          }

          final itemIndex = index - 1;

          // Loader al final
          if (itemIndex == clientes.length) {
            if (hasMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }

          final cliente = clientes[itemIndex];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                cliente.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RUC/CI: ${cliente.ruc}'),
                  if (cliente.ciudad != null && cliente.ciudad!.isNotEmpty)
                    Text(cliente.ciudad!),
                ],
              ),
              trailing: cliente.activo
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red),
              onTap: () => _showClienteDetails(context, cliente),
            ),
          );
        },
      ),
    );
  }

  void _showClienteDetails(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cliente.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'RUC/CI', value: cliente.ruc),
            if (cliente.email != null && cliente.email!.isNotEmpty)
              _DetailRow(label: 'Email', value: cliente.email!),
            if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
              _DetailRow(label: 'Teléfono', value: cliente.telefono!),
            if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
              _DetailRow(label: 'Dirección', value: cliente.direccion!),
            if (cliente.ciudad != null && cliente.ciudad!.isNotEmpty)
              _DetailRow(label: 'Ciudad', value: cliente.ciudad!),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(
                  cliente.activo ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: cliente.activo ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  cliente.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cliente.activo ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
