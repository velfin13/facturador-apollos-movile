import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/factura.dart';

class FacturaListWidget extends StatelessWidget {
  final List<Factura> facturas;

  const FacturaListWidget({super.key, required this.facturas});

  @override
  Widget build(BuildContext context) {
    if (facturas.isEmpty) {
      return const Center(child: Text('No hay facturas disponibles'));
    }

    return ListView.builder(
      itemCount: facturas.length,
      itemBuilder: (context, index) {
        final factura = facturas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.receipt, color: Colors.white),
            ),
            title: Text(
              factura.clienteNombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(factura.fecha)}',
            ),
            trailing: Text(
              '\$${factura.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () {
              // TODO: Navegar a detalle de factura
              _showFacturaDetails(context, factura);
            },
          ),
        );
      },
    );
  }

  void _showFacturaDetails(BuildContext context, Factura factura) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Factura #${factura.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${factura.clienteNombre}'),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(factura.fecha)}'),
            const SizedBox(height: 16),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...factura.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '• ${item.descripcion} x${item.cantidad} = \$${item.subtotal.toStringAsFixed(2)}',
                ),
              ),
            ),
            const Divider(),
            Text(
              'Total: \$${factura.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
