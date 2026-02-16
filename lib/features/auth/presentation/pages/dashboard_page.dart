import 'package:flutter/material.dart';
import '../../domain/entities/usuario.dart';
import '../../../../injection/injection_container.dart';
import '../../../clientes/presentation/bloc/cliente_bloc.dart';
import '../../../clientes/presentation/pages/crear_cliente_page.dart';
import '../../../productos/presentation/pages/crear_producto_page.dart';
import '../../../facturacion/presentation/pages/crear_factura_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardPage extends StatelessWidget {
  final Usuario usuario;

  const DashboardPage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario.nombre,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    usuario.rolActivo!.displayName,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Acciones rápidas
          Text(
            'Acciones rapidas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Grid de acciones según rol
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: _buildQuickActions(context),
          ),

          const SizedBox(height: 24),

          // Info del sistema
          _buildInfoCard(context),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos dias';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  List<Widget> _buildQuickActions(BuildContext context) {
    final actions = <Widget>[];

    // Nueva factura - admin y cliente
    if (usuario.esAdmin || usuario.esCliente) {
      actions.add(
        _QuickActionCard(
          icon: Icons.add_shopping_cart,
          label: 'Nueva Factura',
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearFacturaPage()),
          ),
        ),
      );
    }

    // Nuevo cliente - admin y cliente
    if (usuario.esAdmin || usuario.esCliente) {
      actions.add(
        _QuickActionCard(
          icon: Icons.person_add,
          label: 'Nuevo Cliente',
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => getIt<ClienteBloc>(),
                child: const CrearClientePage(),
              ),
            ),
          ),
        ),
      );
    }

    // Nuevo producto - admin y cliente
    if (usuario.esAdmin || usuario.esCliente) {
      actions.add(
        _QuickActionCard(
          icon: Icons.add_box,
          label: 'Nuevo Producto',
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearProductoPage()),
          ),
        ),
      );
    }

    // Ver reportes - solo admin (por ahora)
    if (usuario.esAdmin) {
      actions.add(
        _QuickActionCard(
          icon: Icons.bar_chart,
          label: 'Reportes',
          color: Colors.blue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reportes proximamente')),
            );
          },
        ),
      );
    }

    return actions;
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Sistema de Facturacion',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getRoleDescription(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDescription() {
    switch (usuario.rolActivo) {
      case UserRole.admin:
        return 'Como administrador tienes acceso completo al sistema: facturas, clientes, productos y reportes.';
      case UserRole.cliente:
        return 'Como cliente puedes gestionar tus clientes, productos y facturas de tu empresa.';
      case null:
        return 'Selecciona un rol para ver las opciones disponibles.';
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
