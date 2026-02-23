import 'package:flutter/material.dart';
import '../../domain/entities/producto.dart';
import '../pages/ajustar_stock_page.dart';

class ProductoListWidget extends StatelessWidget {
  final List<Producto> productos;
  final VoidCallback? onStockAjustado;
  final ValueChanged<Producto>? onToggleStatus;
  final ValueChanged<Producto>? onEdit;

  const ProductoListWidget({
    super.key,
    required this.productos,
    this.onStockAjustado,
    this.onToggleStatus,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 44,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin productos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Presiona + para agregar uno',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: productos.length,
      itemBuilder: (context, index) => _ProductoCard(
        producto: productos[index],
        onStockAjustado: onStockAjustado,
        onToggleStatus: onToggleStatus,
        onEdit: onEdit,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
enum _CardAction { edit, stock, toggle }

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onStockAjustado;
  final ValueChanged<Producto>? onToggleStatus;
  final ValueChanged<Producto>? onEdit;

  const _ProductoCard({
    required this.producto,
    this.onStockAjustado,
    this.onToggleStatus,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = producto.estaActivo;
    final accentColor =
        isActive ? theme.colorScheme.primary : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetails(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.error.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Barra de acento izquierda
                Container(
                  width: 4,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Ícono del producto
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    producto.esBien
                        ? Icons.inventory_2
                        : Icons.design_services,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),

                // Descripción + tags
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.descripcion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _Tag(
                              label: producto.tipoDescripcion,
                              bg: theme.colorScheme.secondaryContainer,
                              fg: theme.colorScheme.onSecondaryContainer,
                            ),
                            if (producto.tieneIva)
                              _Tag(
                                label: 'IVA',
                                bg: Colors.orange.shade100,
                                fg: Colors.orange.shade900,
                              ),
                            if (!isActive)
                              _Tag(
                                label: 'Inactivo',
                                bg: theme.colorScheme.errorContainer,
                                fg: theme.colorScheme.error,
                              ),
                          ],
                        ),
                        if (producto.barra != null &&
                            producto.barra!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 12,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                producto.barra!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Precio + stock
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${producto.precio.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StockChip(stock: producto.stock),
                    ],
                  ),
                ),

                // Menú de acciones (3-dot)
                PopupMenuButton<_CardAction>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.outline,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: _CardAction.edit,
                      child: _MenuTile(
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    PopupMenuItem(
                      value: _CardAction.stock,
                      child: _MenuTile(
                        icon: Icons.tune_outlined,
                        label: 'Ajustar stock',
                        color: Colors.teal.shade600,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: _CardAction.toggle,
                      child: _MenuTile(
                        icon: isActive
                            ? Icons.visibility_off_outlined
                            : Icons.check_circle_outline,
                        label: isActive ? 'Desactivar' : 'Activar',
                        color: isActive
                            ? theme.colorScheme.error
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                  onSelected: (action) async {
                    switch (action) {
                      case _CardAction.edit:
                        onEdit?.call(producto);
                      case _CardAction.stock:
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AjustarStockPage(producto: producto),
                          ),
                        );
                        if (result == true) onStockAjustado?.call();
                      case _CardAction.toggle:
                        onToggleStatus?.call(producto);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = producto.estaActivo;
    final accentColor =
        isActive ? theme.colorScheme.primary : theme.colorScheme.error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, controller) => Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header con ícono y nombre
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      producto.esBien
                          ? Icons.inventory_2
                          : Icons.design_services,
                      color: accentColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.descripcion,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isActive ? Icons.circle : Icons.cancel,
                              size: 10,
                              color:
                                  isActive ? Colors.green.shade600 : accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'Producto activo' : 'Producto inactivo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isActive
                                    ? Colors.green.shade700
                                    : accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: theme.colorScheme.outlineVariant,
            ),

            // Detalle scrollable
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _DetailGrid(producto: producto, theme: theme),
                  const SizedBox(height: 20),

                  // Botones de acción dentro del sheet
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onEdit?.call(producto);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AjustarStockPage(producto: producto),
                              ),
                            );
                            if (result == true) onStockAjustado?.call();
                          },
                          icon: const Icon(Icons.tune_outlined, size: 18),
                          label: const Text('Stock'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailGrid extends StatelessWidget {
  final Producto producto;
  final ThemeData theme;

  const _DetailGrid({required this.producto, required this.theme});

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      _DetailRow('Tipo', producto.tipoDescripcion),
      _DetailRow('Precio 1', '\$${producto.precio1?.toStringAsFixed(2) ?? "0.00"}'),
      if (producto.precio2 != null)
        _DetailRow('Precio 2', '\$${producto.precio2!.toStringAsFixed(2)}'),
      if (producto.precio3 != null)
        _DetailRow('Precio 3', '\$${producto.precio3!.toStringAsFixed(2)}'),
      _DetailRow('IVA', producto.tieneIva ? 'Aplica' : 'No aplica'),
      _DetailRow('Stock', '${producto.stock} unidades'),
      if (producto.barra?.isNotEmpty == true)
        _DetailRow('Cód. de barras', producto.barra!),
      if (producto.fraccion != null)
        _DetailRow('Fracción', '${producto.fraccion} unidades'),
    ];

    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    r.value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}

// ─────────────────────────────────────────────────────────────────────────────

class _StockChip extends StatelessWidget {
  final int stock;
  const _StockChip({required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (stock <= 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = 'Sin stock';
    } else if (stock <= 5) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      label = 'Stock: $stock';
    } else {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = 'Stock: $stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Tag({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuTile({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
