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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        return _ProductoCard(
          producto: producto,
          onStockAjustado: onStockAjustado,
        );
      },
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onStockAjustado;

  const _ProductoCard({
    required this.producto,
    this.onStockAjustado,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = producto.estaActivo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProductoDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono/Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  producto.esBien ? Icons.inventory_2 : Icons.design_services,
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.descripcion,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(
                          context,
                          producto.tipoDescripcion,
                          theme.colorScheme.secondaryContainer,
                          theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 6),
                        if (producto.tieneIva)
                          _buildTag(
                            context,
                            'IVA',
                            Colors.orange.shade100,
                            Colors.orange.shade800,
                          ),
                        if (!isActive) ...[
                          const SizedBox(width: 6),
                          _buildTag(
                            context,
                            'Inactivo',
                            theme.colorScheme.errorContainer,
                            theme.colorScheme.error,
                          ),
                        ],
                      ],
                    ),
                    if (producto.barra != null && producto.barra!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Cod: ${producto.barra}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Precio y stock
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${producto.precio.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: producto.stock > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stock: ${producto.stock}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: producto.stock > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),

              // Botón de ajustar stock
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Ajustar stock',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AjustarStockPage(producto: producto),
                    ),
                  );

                  if (result == true && onStockAjustado != null) {
                    onStockAjustado!();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showProductoDetails(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              producto.descripcion,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Tipo', producto.tipoDescripcion),
            _buildDetailRow('Precio 1', '\$${producto.precio1?.toStringAsFixed(2) ?? "0.00"}'),
            if (producto.precio2 != null)
              _buildDetailRow('Precio 2', '\$${producto.precio2!.toStringAsFixed(2)}'),
            if (producto.precio3 != null)
              _buildDetailRow('Precio 3', '\$${producto.precio3!.toStringAsFixed(2)}'),
            _buildDetailRow('IVA', producto.tieneIva ? 'Si aplica' : 'No aplica'),
            _buildDetailRow('Stock', '${producto.stock} unidades'),
            if (producto.barra != null && producto.barra!.isNotEmpty)
              _buildDetailRow('Codigo de barras', producto.barra!),
            if (producto.fraccion != null)
              _buildDetailRow('Fraccion', '${producto.fraccion} unidades'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  producto.estaActivo ? Icons.check_circle : Icons.cancel,
                  color: producto.estaActivo ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  producto.estaActivo ? 'Producto activo' : 'Producto inactivo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: producto.estaActivo ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
