import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/factura.dart';
import '../bloc/factura_bloc.dart';

class FacturaListWidget extends StatelessWidget {
  final List<Factura> facturas;
  final bool hasMore;
  final int total;
  final VoidCallback? onLoadMore;

  const FacturaListWidget({
    super.key,
    required this.facturas,
    this.hasMore = false,
    this.total = 0,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (facturas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(child: Text('No hay facturas disponibles')),
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
        // header + items + optional loader
        itemCount: facturas.length + 2,
        itemBuilder: (context, index) {
          // Header with count
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
              child: Text(
                'Mostrando ${facturas.length} de $total facturas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          }

          final itemIndex = index - 1;

          // Bottom loader
          if (itemIndex == facturas.length) {
            if (hasMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }

          final factura = facturas[itemIndex];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.receipt, color: Colors.white),
              ),
              title: Text(
                '${factura.numFact ?? 'N/A'} · ${factura.clienteNombre ?? factura.clienteId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(factura.fecha)),
              trailing: Text(
                '\$${factura.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () => _showFacturaDetails(context, factura),
            ),
          );
        },
      ),
    );
  }

  void _showFacturaDetails(BuildContext outerContext, Factura factura) {
    final bloc = outerContext.read<FacturaBloc>();
    bloc.add(GetFacturaDetailsEvent(factura.id));

    showDialog(
      context: outerContext,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: AlertDialog(
          title: Text('Factura ${factura.numFact ?? factura.id}'),
          content: SingleChildScrollView(
            child: BlocBuilder<FacturaBloc, FacturaState>(
              buildWhen: (prev, curr) =>
                  curr is FacturaDetailsLoaded || curr is FacturaError,
              builder: (ctx, state) {
                final detalle = state is FacturaDetailsLoaded &&
                        state.factura.id == factura.id
                    ? state.factura
                    : null;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cliente: ${factura.clienteNombre ?? factura.clienteId}'),
                    Text('Fecha: ${DateFormat('dd/MM/yyyy').format(factura.fecha)}'),
                    if (factura.observacion != null && factura.observacion!.isNotEmpty)
                      Text('Observación: ${factura.observacion}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Items:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (detalle == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (detalle.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 8, top: 4),
                        child: Text('No hay detalles disponibles'),
                      )
                    else
                      ...detalle.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            '• ${item.productoNombre ?? item.productoId} x${item.cantidad.toInt()} = \$${(item.cantidad * item.valor).toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                    const Divider(),
                    if (factura.descTotal > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Descuento: -\$${factura.descTotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Subtotal: \$${factura.subtotal.toStringAsFixed(2)}'),
                    ),
                    if (factura.ivaTotal > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('IVA: \$${factura.ivaTotal.toStringAsFixed(2)}'),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Total: \$${factura.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
