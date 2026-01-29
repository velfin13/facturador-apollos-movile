import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/entities/usuario.dart';
import '../../../clientes/presentation/pages/clientes_page.dart';
import '../../../productos/presentation/pages/productos_page.dart';
import '../../../facturacion/presentation/pages/facturas_page.dart';
import '../../../facturacion/presentation/pages/crear_factura_page.dart';
import 'dashboard_page.dart';

class HomePage extends StatefulWidget {
  final Usuario usuario;

  const HomePage({super.key, required this.usuario});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  List<_NavItem> get _navItems {
    final items = <_NavItem>[];

    // Dashboard - todos los roles
    items.add(_NavItem(
      label: 'Inicio',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      page: DashboardPage(usuario: widget.usuario),
    ));

    // Facturas - admin y contador
    if (widget.usuario.esAdmin || widget.usuario.esContador) {
      items.add(const _NavItem(
        label: 'Facturas',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        page: FacturasPage(),
      ));
    }

    // Nueva Factura - admin y vendedor
    if (widget.usuario.esAdmin || widget.usuario.esVendedor) {
      items.add(const _NavItem(
        label: 'Facturar',
        icon: Icons.add_circle_outline,
        activeIcon: Icons.add_circle,
        page: CrearFacturaPage(),
      ));
    }

    // Clientes - solo admin
    if (widget.usuario.esAdmin) {
      items.add(const _NavItem(
        label: 'Clientes',
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        page: ClientesPage(),
      ));
    }

    // Productos - solo admin
    if (widget.usuario.esAdmin) {
      items.add(const _NavItem(
        label: 'Productos',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        page: ProductosPage(),
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _navItems;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(items[_currentIndex].label),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showProfileSheet(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: items.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: items.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
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
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                widget.usuario.nombre.isNotEmpty
                    ? widget.usuario.nombre[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.usuario.nombre,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.usuario.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(widget.usuario.rol).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.usuario.rol.displayName,
                style: TextStyle(
                  color: _getRoleColor(widget.usuario.rol),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Cerrar sesion',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text('Estas seguro de que deseas cerrar sesion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.vendedor:
        return Colors.blue;
      case UserRole.contador:
        return Colors.teal;
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}
