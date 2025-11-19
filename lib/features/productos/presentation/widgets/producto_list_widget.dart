import 'package:flutter/material.dart';
import '../../domain/entities/producto.dart';
import '../pages/ajustar_stock_page.dart';

class ProductoListWidget extends StatelessWidget {
  final List<Producto> productos;
  final VoidCallback? onStockAjustado;

  const ProductoListWidget({
    super.key,
    required this.productos,
    this.onStockAjustado,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return const Center(child: Text('No hay productos disponibles'));
    }

    return ListView.builder(
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: producto.disponible
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              child: const Icon(Icons.inventory_2, color: Colors.white),
            ),
            title: Text(
              producto.descripcion,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio: \$${producto.precio.toStringAsFixed(2)}'),
                if (producto.barra != null)
                  Text('Código de barras: ${producto.barra}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock: ${producto.stock}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: producto.stock > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '\$${producto.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.inventory),
                  tooltip: 'Ajustar stock',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AjustarStockPage(producto: producto),
                      ),
                    );

                    if (result == true && onStockAjustado != null) {
                      onStockAjustado!();
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              _showProductoDetails(context, producto);
            },
          ),
        );
      },
    );
  }

  void _showProductoDetails(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(producto.descripcion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.barra != null)
              Text('Código de barras: ${producto.barra}'),
            const SizedBox(height: 8),
            Text('Precio: \$${producto.precio.toStringAsFixed(2)}'),
            if (producto.costo != null)
              Text('Costo: \$${producto.costo!.toStringAsFixed(2)}'),
            if (producto.costo != null)
              Text('Margen: ${producto.margen.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('Stock: ${producto.stock} unidades'),
            Text('IVA: ${producto.tieneIva ? "Sí" : "No"}'),
            const SizedBox(height: 8),
            Text(
              'Estado: ${producto.activo ? "Activo" : "Inactivo"}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: producto.activo ? Colors.green : Colors.red,
              ),
            ),
            if (!producto.disponible)
              const Text(
                'SIN STOCK DISPONIBLE',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
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
