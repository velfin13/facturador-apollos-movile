import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/entities/usuario.dart';
import '../../../clientes/presentation/pages/clientes_page.dart';
import '../../../productos/presentation/pages/productos_page.dart';
import '../../../facturacion/presentation/pages/facturas_page.dart';
import '../../../facturacion/presentation/pages/crear_factura_page.dart';

class HomePage extends StatelessWidget {
  final Usuario usuario;

  const HomePage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facturador - ${usuario.rol.displayName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showUserInfo(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          if (usuario.esAdmin || usuario.esContador)
            _buildMenuCard(
              context,
              'Facturas',
              Icons.receipt_long,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FacturasPage()),
              ),
            ),
          if (usuario.esAdmin || usuario.esVendedor)
            _buildMenuCard(
              context,
              'Nueva Factura',
              Icons.add_box,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrearFacturaPage()),
              ),
            ),
          if (usuario.esAdmin)
            _buildMenuCard(
              context,
              'Clientes',
              Icons.people,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientesPage()),
              ),
            ),
          if (usuario.esAdmin)
            _buildMenuCard(
              context,
              'Productos',
              Icons.inventory,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductosPage()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${usuario.nombre}'),
            Text('Email: ${usuario.email}'),
            Text('Rol: ${usuario.rol.displayName}'),
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
