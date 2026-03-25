import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection/injection_container.dart';
import '../../../clientes/presentation/bloc/cliente_bloc.dart';
import '../../../productos/presentation/bloc/producto_bloc.dart';
import '../bloc/factura_bloc.dart';
import '../widgets/factura_list_widget.dart';
import 'crear_factura_page.dart';

enum _FiltroFecha { todos, hoy, semana, mes }

class FacturasPage extends StatefulWidget {
  const FacturasPage({super.key});

  @override
  State<FacturasPage> createState() => _FacturasPageState();
}

class _FacturasPageState extends State<FacturasPage>
    with SingleTickerProviderStateMixin {
  _FiltroFecha _filtroFecha = _FiltroFecha.todos;
  final _searchController = TextEditingController();
  Timer? _debounce;
  late TabController _tabController;

  // Uso de suscripción
  Map<String, dynamic>? _uso;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _cargarUso();
  }

  Future<void> _cargarUso() async {
    try {
      final response = await getIt<DioClient>().get('/Ventas/uso');
      if (response.data is Map && response.data['data'] != null) {
        setState(() => _uso = response.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _applyDateFilter(BuildContext context, _FiltroFecha filtro) {
    setState(() => _filtroFecha = filtro);
    final now = DateTime.now();
    switch (filtro) {
      case _FiltroFecha.todos:
        context.read<FacturaBloc>().add(const FilterByDateRangeEvent());
      case _FiltroFecha.hoy:
        context
            .read<FacturaBloc>()
            .add(FilterByDateRangeEvent(desde: now, hasta: now));
      case _FiltroFecha.semana:
        context.read<FacturaBloc>().add(
              FilterByDateRangeEvent(
                  desde: now.subtract(const Duration(days: 7)), hasta: now),
            );
      case _FiltroFecha.mes:
        context.read<FacturaBloc>().add(
              FilterByDateRangeEvent(
                  desde: DateTime(now.year, now.month, 1), hasta: now),
            );
    }
  }

  void _onSearchChanged(BuildContext context, String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<FacturaBloc>().add(SearchFacturasEvent(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => getIt<FacturaBloc>()..add(GetFacturasEvent()),
      child: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              // TabBar
              Container(
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: cs.primary,
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: cs.primary,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.receipt_long, size: 18),
                      text: 'Facturas',
                    ),
                    Tab(
                      icon: Icon(Icons.assignment_return_outlined, size: 18),
                      text: 'Notas de Crédito',
                    ),
                  ],
                ),
              ),
              // Uso de plan
              if (_uso != null) _UsoBanner(uso: _uso!, tabIndex: _tabController.index),

              // Buscador
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0
                        ? 'Buscar por # factura o cliente...'
                        : 'Buscar por # nota de crédito o cliente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<FacturaBloc>()
                                  .add(SearchFacturasEvent(''));
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (v) => _onSearchChanged(context, v),
                ),
              ),
              // Chips de filtro por fecha
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    _DateChip(
                      label: 'Todos',
                      selected: _filtroFecha == _FiltroFecha.todos,
                      onTap: () =>
                          _applyDateFilter(context, _FiltroFecha.todos),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: 'Hoy',
                      selected: _filtroFecha == _FiltroFecha.hoy,
                      onTap: () =>
                          _applyDateFilter(context, _FiltroFecha.hoy),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: '7 días',
                      selected: _filtroFecha == _FiltroFecha.semana,
                      onTap: () =>
                          _applyDateFilter(context, _FiltroFecha.semana),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: 'Este mes',
                      selected: _filtroFecha == _FiltroFecha.mes,
                      onTap: () =>
                          _applyDateFilter(context, _FiltroFecha.mes),
                    ),
                  ],
                ),
              ),
              // Lista filtrada por tab
              Expanded(
                child: BlocBuilder<FacturaBloc, FacturaState>(
                  buildWhen: (prev, curr) =>
                      curr is FacturaLoading ||
                      curr is FacturaLoaded ||
                      curr is FacturaError,
                  builder: (context, state) {
                    if (state is FacturaLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is FacturaLoaded) {
                      final tipoFiltro =
                          _tabController.index == 0 ? 'FV' : 'NC';
                      final filtered = state.facturas
                          .where((f) => f.tipo == tipoFiltro)
                          .toList();
                      return RefreshIndicator(
                        onRefresh: () async =>
                            context.read<FacturaBloc>().add(GetFacturasEvent()),
                        child: FacturaListWidget(
                          facturas: filtered,
                          hasMore: state.hasMore,
                          total: filtered.length,
                          onLoadMore: () => context
                              .read<FacturaBloc>()
                              .add(LoadMoreFacturasEvent()),
                        ),
                      );
                    } else if (state is FacturaError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${state.message}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<FacturaBloc>()
                                  .add(GetFacturasEvent()),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Center(
                      child: Text('Presiona el botón para cargar facturas'),
                    );
                  },
                ),
              ),
            ],
          ),
          // Solo mostrar FAB en la pestaña de facturas
          floatingActionButton: _tabController.index == 0
              ? FloatingActionButton(
                  heroTag: 'fab_facturas',
                  onPressed: () async {
                    final facturaBloc = context.read<FacturaBloc>();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider(
                                create: (_) => getIt<ClienteBloc>()),
                            BlocProvider(
                                create: (_) => getIt<ProductoBloc>()),
                            BlocProvider.value(value: facturaBloc),
                          ],
                          child: const CrearFacturaPage(),
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      facturaBloc.add(GetFacturasEvent());
                    }
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade400),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _UsoBanner extends StatelessWidget {
  final Map<String, dynamic> uso;
  final int tabIndex;

  const _UsoBanner({required this.uso, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final plan = uso['subscriptionType']?.toString() ?? 'Plan';
    final esGratis = uso['esGratis'] == true;

    final int usadas;
    final int limite;
    final String tipo;

    if (tabIndex == 0) {
      usadas = (uso['currentInvoiceCount'] as num?)?.toInt() ?? 0;
      limite = (uso['invoiceLimit'] as num?)?.toInt() ?? 10;
      tipo = 'facturas';
    } else {
      usadas = (uso['currentNotaCreditoCount'] as num?)?.toInt() ?? 0;
      limite = (uso['notaCreditoLimit'] as num?)?.toInt() ?? 10;
      tipo = 'notas de crédito';
    }

    final restantes = limite == -1 ? -1 : (limite - usadas).clamp(0, limite);
    final porcentaje = limite == -1 ? 0.0 : (usadas / limite).clamp(0.0, 1.0);
    final esCritico = limite != -1 && restantes <= 2;

    final barColor = limite == -1
        ? AppTheme.brand
        : esCritico
            ? AppTheme.danger
            : AppTheme.brand;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, size: 16, color: AppTheme.brand),
              const SizedBox(width: 6),
              Text(
                plan,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (esGratis) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Uso único',
                    style: TextStyle(fontSize: 9, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              if (limite == -1)
                Text('Ilimitado', style: TextStyle(fontSize: 12, color: AppTheme.brand, fontWeight: FontWeight.bold))
              else
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    children: [
                      TextSpan(
                        text: '$usadas',
                        style: TextStyle(fontWeight: FontWeight.bold, color: esCritico ? AppTheme.danger : AppTheme.brand),
                      ),
                      TextSpan(text: ' / $limite $tipo'),
                    ],
                  ),
                ),
            ],
          ),
          if (limite != -1) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentaje,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
