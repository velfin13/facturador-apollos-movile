import 'package:flutter/material.dart';
import '../../domain/entities/usuario.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection/injection_container.dart';
import '../../../clientes/presentation/bloc/cliente_bloc.dart';
import '../../../clientes/presentation/pages/crear_cliente_page.dart';
import '../../../productos/presentation/pages/crear_producto_page.dart';
import '../../../facturacion/presentation/pages/crear_factura_page.dart';
import '../../../facturacion/presentation/pages/estadisticas_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardPage extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback? onUpgrade;

  const DashboardPage({super.key, required this.usuario, this.onUpgrade});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _uso;

  Usuario get usuario => widget.usuario;

  @override
  void initState() {
    super.initState();
    _cargarUso();
  }

  Future<void> _cargarUso() async {
    try {
      final response = await getIt<DioClient>().get('/Ventas/uso');
      if (response.data is Map && response.data['data'] != null) {
        if (mounted) setState(() => _uso = response.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _cargarUso,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                  theme.colorScheme.primary.withValues(alpha: 0.8),
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
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
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

          const SizedBox(height: 16),

          // Tarjeta de plan y uso
          if (_uso != null) _PlanUsageCard(uso: _uso!, onUpgrade: widget.onUpgrade),

          const SizedBox(height: 20),

          // Acciones rápidas
          Text(
            'Acciones rapidas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

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

          _buildInfoCard(context),
        ],
      ),
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

    actions.add(
      _QuickActionCard(
        icon: Icons.bar_chart,
        label: 'Estadísticas',
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstadisticasPage()),
        ),
      ),
    );

    return actions;
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sistema de Facturacion',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getRoleDescription(),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de plan y uso
// ─────────────────────────────────────────────────────────────────────────────

class _PlanUsageCard extends StatelessWidget {
  final Map<String, dynamic> uso;
  final VoidCallback? onUpgrade;

  const _PlanUsageCard({required this.uso, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final plan = uso['subscriptionType']?.toString() ?? 'Plan';
    final esGratis = uso['esGratis'] == true;

    final fvUsadas = (uso['currentInvoiceCount'] as num?)?.toInt() ?? 0;
    final fvLimite = (uso['invoiceLimit'] as num?)?.toInt() ?? 10;
    final ncUsadas = (uso['currentNotaCreditoCount'] as num?)?.toInt() ?? 0;
    final ncLimite = (uso['notaCreditoLimit'] as num?)?.toInt() ?? 10;

    final fvPorcentaje = fvLimite == -1 ? 0.0 : (fvUsadas / fvLimite).clamp(0.0, 1.0);
    final ncPorcentaje = ncLimite == -1 ? 0.0 : (ncUsadas / ncLimite).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del plan
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium, size: 20, color: AppTheme.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      esGratis ? '10 facturas + 10 NC (uso único)' : 'Se renueva mensualmente',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              if (esGratis)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Gratis',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Barras de uso
          _UsageBar(
            label: 'Facturas',
            icon: Icons.receipt_long,
            used: fvUsadas,
            limit: fvLimite,
            percentage: fvPorcentaje,
            color: AppTheme.brand,
          ),

          const SizedBox(height: 12),

          _UsageBar(
            label: 'Notas de Crédito',
            icon: Icons.assignment_return_outlined,
            used: ncUsadas,
            limit: ncLimite,
            percentage: ncPorcentaje,
            color: Colors.orange.shade700,
          ),

          const SizedBox(height: 14),

          // Botón actualizar plan
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.rocket_launch_outlined, size: 16),
              label: Text(esGratis ? 'Actualizar plan' : 'Cambiar plan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brand,
                side: BorderSide(color: AppTheme.brand.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int used;
  final int limit;
  final double percentage;
  final Color color;

  const _UsageBar({
    required this.label,
    required this.icon,
    required this.used,
    required this.limit,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final restantes = limit == -1 ? -1 : (limit - used).clamp(0, limit);
    final esCritico = limit != -1 && restantes <= 2;
    final barColor = esCritico ? AppTheme.danger : color;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const Spacer(),
            if (limit == -1)
              Text('Ilimitado', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold))
            else
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  children: [
                    TextSpan(
                      text: '$used',
                      style: TextStyle(fontWeight: FontWeight.bold, color: esCritico ? AppTheme.danger : color),
                    ),
                    TextSpan(text: ' / $limit'),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de acción rápida
// ─────────────────────────────────────────────────────────────────────────────

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
      color: color.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.2),
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
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
