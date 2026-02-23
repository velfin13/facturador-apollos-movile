import 'package:flutter/material.dart';
import '../../domain/entities/cliente.dart';

class ClienteListWidget extends StatelessWidget {
  final List<Cliente> clientes;
  final bool hasMore;
  final int total;
  final VoidCallback? onLoadMore;
  final ValueChanged<Cliente>? onEdit;

  const ClienteListWidget({
    super.key,
    required this.clientes,
    this.hasMore = false,
    this.total = 0,
    this.onLoadMore,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (clientes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 44,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin clientes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Presiona + para agregar uno',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: clientes.length + 2,
        itemBuilder: (context, index) {
          // Header contador
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'Mostrando ${clientes.length} de $total clientes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
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

          return _ClienteCard(
            cliente: clientes[itemIndex],
            onEdit: onEdit,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final ValueChanged<Cliente>? onEdit;

  const _ClienteCard({required this.cliente, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = cliente.activo;
    final accentColor =
        isActive ? theme.colorScheme.primary : theme.colorScheme.error;
    final initial = cliente.nombre.isNotEmpty
        ? cliente.nombre[0].toUpperCase()
        : '?';

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

                // Avatar con iniciales
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Contenido principal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 12,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              cliente.ruc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (cliente.ciudad?.isNotEmpty == true ||
                            cliente.telefono?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (cliente.ciudad?.isNotEmpty == true) ...[
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  cliente.ciudad!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (cliente.ciudad?.isNotEmpty == true &&
                                  cliente.telefono?.isNotEmpty == true)
                                Text(
                                  '  •  ',
                                  style: TextStyle(
                                    color: theme.colorScheme.outline,
                                    fontSize: 11,
                                  ),
                                ),
                              if (cliente.telefono?.isNotEmpty == true) ...[
                                Icon(
                                  Icons.phone_outlined,
                                  size: 12,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  cliente.telefono!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Indicador de estado
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _StatusBadge(isActive: isActive),
                ),

                // Menú de acciones
                PopupMenuButton<_ClienteAction>(
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
                      value: _ClienteAction.edit,
                      child: _MenuTile(
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    PopupMenuItem(
                      value: _ClienteAction.details,
                      child: _MenuTile(
                        icon: Icons.info_outline,
                        label: 'Ver detalles',
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                  onSelected: (action) {
                    switch (action) {
                      case _ClienteAction.edit:
                        onEdit?.call(cliente);
                      case _ClienteAction.details:
                        _showDetails(context);
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
    final isActive = cliente.activo;
    final accentColor =
        isActive ? theme.colorScheme.primary : theme.colorScheme.error;
    final initial = cliente.nombre.isNotEmpty
        ? cliente.nombre[0].toUpperCase()
        : '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.35,
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

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: accentColor.withValues(alpha: 0.12),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
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
                              color: isActive
                                  ? Colors.green.shade600
                                  : accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'Cliente activo' : 'Cliente inactivo',
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

            // Datos
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _DetailItem(
                    icon: Icons.badge_outlined,
                    label: 'RUC / CI',
                    value: cliente.ruc,
                  ),
                  if (cliente.email?.isNotEmpty == true)
                    _DetailItem(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: cliente.email!,
                    ),
                  if (cliente.telefono?.isNotEmpty == true)
                    _DetailItem(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: cliente.telefono!,
                    ),
                  if (cliente.ciudad?.isNotEmpty == true)
                    _DetailItem(
                      icon: Icons.location_city_outlined,
                      label: 'Ciudad',
                      value: cliente.ciudad!,
                    ),
                  if (cliente.direccion?.isNotEmpty == true)
                    _DetailItem(
                      icon: Icons.location_on_outlined,
                      label: 'Dirección',
                      value: cliente.direccion!,
                    ),
                  const SizedBox(height: 20),

                  // Botón editar
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onEdit?.call(cliente);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar cliente'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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

enum _ClienteAction { edit, details }

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Activo' : 'Inactivo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
