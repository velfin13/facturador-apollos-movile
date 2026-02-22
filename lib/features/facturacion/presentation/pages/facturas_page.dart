import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _FacturasPageState extends State<FacturasPage> {
  _FiltroFecha _filtroFecha = _FiltroFecha.todos;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _applyDateFilter(BuildContext context, _FiltroFecha filtro) {
    setState(() => _filtroFecha = filtro);
    final now = DateTime.now();
    switch (filtro) {
      case _FiltroFecha.todos:
        context.read<FacturaBloc>().add(const FilterByDateRangeEvent());
      case _FiltroFecha.hoy:
        context.read<FacturaBloc>().add(FilterByDateRangeEvent(desde: now, hasta: now));
      case _FiltroFecha.semana:
        context.read<FacturaBloc>().add(
          FilterByDateRangeEvent(desde: now.subtract(const Duration(days: 7)), hasta: now),
        );
      case _FiltroFecha.mes:
        context.read<FacturaBloc>().add(
          FilterByDateRangeEvent(desde: DateTime(now.year, now.month, 1), hasta: now),
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
    return BlocProvider(
      create: (_) => getIt<FacturaBloc>()..add(GetFacturasEvent()),
      child: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              // Buscador
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por # factura o cliente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<FacturaBloc>().add(SearchFacturasEvent(''));
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
                      onTap: () => _applyDateFilter(context, _FiltroFecha.todos),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: 'Hoy',
                      selected: _filtroFecha == _FiltroFecha.hoy,
                      onTap: () => _applyDateFilter(context, _FiltroFecha.hoy),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: '7 días',
                      selected: _filtroFecha == _FiltroFecha.semana,
                      onTap: () => _applyDateFilter(context, _FiltroFecha.semana),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: 'Este mes',
                      selected: _filtroFecha == _FiltroFecha.mes,
                      onTap: () => _applyDateFilter(context, _FiltroFecha.mes),
                    ),
                  ],
                ),
              ),
              // Lista
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
                      return RefreshIndicator(
                        onRefresh: () async =>
                            context.read<FacturaBloc>().add(GetFacturasEvent()),
                        child: FacturaListWidget(
                          facturas: state.facturas,
                          hasMore: state.hasMore,
                          total: state.total,
                          onLoadMore: () =>
                              context.read<FacturaBloc>().add(LoadMoreFacturasEvent()),
                        ),
                      );
                    } else if (state is FacturaError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${state.message}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  context.read<FacturaBloc>().add(GetFacturasEvent()),
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
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_facturas',
            onPressed: () async {
              final facturaBloc = context.read<FacturaBloc>();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider(create: (_) => getIt<ClienteBloc>()),
                      BlocProvider(create: (_) => getIt<ProductoBloc>()),
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
          ),
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
