import 'package:flutter/material.dart';
import '../../domain/entities/cliente.dart';

class ClienteListWidget extends StatelessWidget {
  final List<Cliente> clientes;

  const ClienteListWidget({super.key, required this.clientes});

  @override
  Widget build(BuildContext context) {
    if (clientes.isEmpty) {
      return const Center(child: Text('No hay clientes disponibles'));
    }

    return ListView.builder(
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              cliente.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RUC/CI: ${cliente.ruc}'),
                if (cliente.email != null) Text('Email: ${cliente.email}'),
              ],
            ),
            trailing: cliente.activo
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.cancel, color: Colors.red),
            onTap: () {
              _showClienteDetails(context, cliente);
            },
          ),
        );
      },
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
            Text('RUC: ${cliente.ruc}'),
            if (cliente.email != null) Text('Email: ${cliente.email}'),
            if (cliente.telefono != null) Text('Teléfono: ${cliente.telefono}'),
            if (cliente.direccion != null)
              Text('Dirección: ${cliente.direccion}'),
            if (cliente.ciudad != null) Text('Ciudad: ${cliente.ciudad}'),
            const SizedBox(height: 8),
            Text(
              'Estado: ${cliente.activo ? "Activo" : "Inactivo"}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cliente.activo ? Colors.green : Colors.red,
              ),
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
