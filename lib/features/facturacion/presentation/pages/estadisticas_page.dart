import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/periodo_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection/injection_container.dart';
import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,##0.00', 'es');

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final periodo = getIt<PeriodoManager>().periodoActual;
      final res = await getIt<DioClient>().get('/Estadisticas/$periodo');
      if (res.data is Map && res.data['data'] != null) {
        setState(() => _data = res.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('No se pudieron cargar las estadísticas'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResumen(),
                        const SizedBox(height: 20),
                        _buildTotalesDeclaracion(),
                        const SizedBox(height: 20),
                        _buildVentasPorDia(),
                        const SizedBox(height: 20),
                        _buildTopClientes(),
                        const SizedBox(height: 20),
                        _buildTopProductos(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildResumen() {
    final r = _data!['resumen'] as Map<String, dynamic>? ?? {};
    final ventas = (r['ventasTotales'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total ventas grande
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.brand, AppTheme.brandDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total ventas', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              const SizedBox(height: 4),
              Text('\$${_fmt.format(ventas)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Mini cards
        Row(
          children: [
            Expanded(child: _MiniStat(
              icon: Icons.receipt_long, color: AppTheme.brand,
              label: 'Facturas', value: '${r['totalFacturas'] ?? 0}',
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStat(
              icon: Icons.check_circle_outline, color: AppTheme.success,
              label: 'Autorizadas', value: '${r['facturasAutorizadas'] ?? 0}',
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStat(
              icon: Icons.schedule, color: Colors.orange.shade700,
              label: 'Pendientes', value: '${r['facturasPendientes'] ?? 0}',
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MiniStat(
              icon: Icons.assignment_return_outlined, color: Colors.purple,
              label: 'Notas Crédito', value: '${r['totalNC'] ?? 0}',
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStat(
              icon: Icons.people_outline, color: Colors.teal,
              label: 'Clientes', value: '${r['clientesActivos'] ?? 0}',
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStat(
              icon: Icons.inventory_2_outlined, color: Colors.indigo,
              label: 'Productos', value: '${r['productosActivos'] ?? 0}',
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalesDeclaracion() {
    final totales = (_data!['totalesDeclaracion'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (totales.isEmpty) {
      return _SeccionVacia(titulo: 'Resumen para declaraciones', mensaje: 'Sin datos');
    }

    // Buscar FV y NC
    final fv = totales.firstWhere((t) => t['tipo'] == 'FV', orElse: () => {});
    final nc = totales.firstWhere((t) => t['tipo'] == 'NC', orElse: () => {});

    final fvSub = (fv['subtotal'] as num?)?.toDouble() ?? 0;
    final fvIva = (fv['iva'] as num?)?.toDouble() ?? 0;
    final fvTotal = (fv['total'] as num?)?.toDouble() ?? 0;
    final fvDesc = (fv['descuento'] as num?)?.toDouble() ?? 0;
    final fvDocs = (fv['documentos'] as num?)?.toInt() ?? 0;

    final ncSub = (nc['subtotal'] as num?)?.toDouble() ?? 0;
    final ncIva = (nc['iva'] as num?)?.toDouble() ?? 0;
    final ncTotal = (nc['total'] as num?)?.toDouble() ?? 0;
    final ncDocs = (nc['documentos'] as num?)?.toInt() ?? 0;

    // Neto = Ventas - NC
    final netoSub = fvSub - ncSub;
    final netoIva = fvIva - ncIva;
    final netoTotal = fvTotal - ncTotal;

    return _Seccion(
      titulo: 'Resumen para declaraciones',
      child: Column(
        children: [
          // Tabla
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(flex: 3, child: Text('Concepto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Subtotal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('IVA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600), textAlign: TextAlign.right)),
                    ],
                  ),
                ),

                // Ventas
                _DeclaracionRow(
                  label: 'Ventas ($fvDocs)',
                  subtotal: fvSub,
                  iva: fvIva,
                  total: fvTotal,
                  color: AppTheme.brand,
                ),

                if (fvDesc > 0)
                  _DeclaracionRow(
                    label: 'Descuentos',
                    subtotal: -fvDesc,
                    iva: 0,
                    total: -fvDesc,
                    color: Colors.orange.shade700,
                  ),

                // NC
                if (ncDocs > 0)
                  _DeclaracionRow(
                    label: 'Notas Crédito ($ncDocs)',
                    subtotal: -ncSub,
                    iva: -ncIva,
                    total: -ncTotal,
                    color: Colors.red.shade600,
                  ),

                // Divider
                Divider(height: 1, color: Colors.grey.shade300),

                // Neto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(flex: 3, child: Text('NETO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('\$${_fmt.format(netoSub)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('\$${_fmt.format(netoIva)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('\$${_fmt.format(netoTotal)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.brand), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentasPorDia() {
    final ventas = (_data!['ventasPorDia'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (ventas.isEmpty) {
      return _SeccionVacia(titulo: 'Ventas por día', mensaje: 'Sin ventas en los últimos 30 días');
    }

    final maxTotal = ventas.map((v) => (v['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b);

    return _Seccion(
      titulo: 'Ventas últimos 30 días',
      child: Column(
        children: ventas.map((v) {
          final fecha = v['fecha']?.toString() ?? '';
          final total = (v['total'] as num).toDouble();
          final cant = v['cantidad'] ?? 0;
          final pct = maxTotal > 0 ? total / maxTotal : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    fecha.length >= 10 ? '${fecha.substring(8, 10)}/${fecha.substring(5, 7)}' : fecha,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 18,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.brand),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 75,
                  child: Text(
                    '\$${_fmt.format(total)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 25,
                  child: Text(
                    '($cant)',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopClientes() {
    final clientes = (_data!['topClientes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (clientes.isEmpty) {
      return _SeccionVacia(titulo: 'Top clientes', mensaje: 'Sin datos');
    }

    return _Seccion(
      titulo: 'Top clientes',
      child: Column(
        children: clientes.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: i == 0 ? Colors.amber.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: i == 0 ? Colors.amber.shade800 : Colors.grey.shade600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['cliente']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${c['facturas']} facturas', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Text('\$${_fmt.format((c['total'] as num).toDouble())}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.brand)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProductos() {
    final productos = (_data!['topProductos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (productos.isEmpty) {
      return _SeccionVacia(titulo: 'Top productos', mensaje: 'Sin datos');
    }

    return _Seccion(
      titulo: 'Productos más vendidos',
      child: Column(
        children: productos.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: i == 0 ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: i == 0 ? Colors.green.shade800 : Colors.grey.shade600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['producto']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${(p['cantidadVendida'] as num).toInt()} vendidos', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Text('\$${_fmt.format((p['totalVendido'] as num).toDouble())}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.success)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DeclaracionRow extends StatelessWidget {
  final String label;
  final double subtotal;
  final double iva;
  final double total;
  final Color color;

  const _DeclaracionRow({
    required this.label, required this.subtotal,
    required this.iva, required this.total, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('\$${_fmt.format(subtotal.abs())}', style: TextStyle(fontSize: 12, color: subtotal < 0 ? Colors.red.shade600 : null), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('\$${_fmt.format(iva.abs())}', style: TextStyle(fontSize: 12, color: iva < 0 ? Colors.red.shade600 : null), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('\$${_fmt.format(total.abs())}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: total < 0 ? Colors.red.shade600 : color), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _SeccionVacia extends StatelessWidget {
  final String titulo;
  final String mensaje;

  const _SeccionVacia({required this.titulo, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: titulo,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(mensaje, style: TextStyle(color: Colors.grey.shade400)),
        ),
      ),
    );
  }
}
