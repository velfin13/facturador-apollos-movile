import 'package:flutter/material.dart';
import '../../domain/entities/producto.dart';

class ProductoListWidget extends StatelessWidget {
  final List<Producto> productos;

  const ProductoListWidget({super.key, required this.productos});

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
              producto.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código: ${producto.codigo}'),
                Text('Stock: ${producto.stock} unidades'),
                if (producto.categoria != null)
                  Text('Categoría: ${producto.categoria}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${producto.precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (!producto.disponible)
                  const Text(
                    'Sin stock',
                    style: TextStyle(color: Colors.red, fontSize: 12),
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
        title: Text(producto.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${producto.codigo}'),
            if (producto.descripcion != null)
              Text('Descripción: ${producto.descripcion}'),
            const SizedBox(height: 8),
            Text('Precio: \$${producto.precio.toStringAsFixed(2)}'),
            if (producto.costo != null)
              Text('Costo: \$${producto.costo!.toStringAsFixed(2)}'),
            if (producto.costo != null)
              Text('Margen: ${producto.margen.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('Stock: ${producto.stock} unidades'),
            if (producto.categoria != null)
              Text('Categoría: ${producto.categoria}'),
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
