import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection/injection_container.dart';
import '../bloc/cliente_bloc.dart';
import '../widgets/cliente_list_widget.dart';
import 'crear_cliente_page.dart';

enum _FiltroEstadoCliente { todos, activos, inactivos }

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  _FiltroEstadoCliente _filtro = _FiltroEstadoCliente.todos;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _activoFromFiltro(_FiltroEstadoCliente filtro) {
    switch (filtro) {
      case _FiltroEstadoCliente.activos:
        return 'S';
      case _FiltroEstadoCliente.inactivos:
        return 'N';
      case _FiltroEstadoCliente.todos:
        return '';
    }
  }

  void _applyStatusFilter(BuildContext context, _FiltroEstadoCliente filtro) {
    setState(() => _filtro = filtro);
    context.read<ClienteBloc>().add(
      FilterClienteStatusEvent(_activoFromFiltro(filtro)),
    );
  }

  void _onSearchChanged(BuildContext context, String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<ClienteBloc>().add(SearchClientesEvent(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClienteBloc>()..add(GetClientesEvent()),
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
                    hintText: 'Buscar por nombre, RUC o ciudad...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ClienteBloc>().add(SearchClientesEvent(''));
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (v) => _onSearchChanged(context, v),
                ),
              ),
              // Chips de filtro por estado
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      selected: _filtro == _FiltroEstadoCliente.todos,
                      onTap: () => _applyStatusFilter(context, _FiltroEstadoCliente.todos),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Activos',
                      selected: _filtro == _FiltroEstadoCliente.activos,
                      onTap: () => _applyStatusFilter(context, _FiltroEstadoCliente.activos),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inactivos',
                      selected: _filtro == _FiltroEstadoCliente.inactivos,
                      onTap: () => _applyStatusFilter(context, _FiltroEstadoCliente.inactivos),
                    ),
                  ],
                ),
              ),
              // Lista
              Expanded(
                child: BlocBuilder<ClienteBloc, ClienteState>(
                  buildWhen: (prev, curr) =>
                      curr is ClienteLoading ||
                      curr is ClienteLoaded ||
                      curr is ClienteError,
                  builder: (context, state) {
                    if (state is ClienteLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ClienteLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async =>
                            context.read<ClienteBloc>().add(GetClientesEvent()),
                        child: ClienteListWidget(
                          clientes: state.clientes,
                          hasMore: state.hasMore,
                          total: state.total,
                          onLoadMore: () =>
                              context.read<ClienteBloc>().add(LoadMoreClientesEvent()),
                        ),
                      );
                    } else if (state is ClienteError) {
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
                                  context.read<ClienteBloc>().add(GetClientesEvent()),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Center(child: Text('No hay datos'));
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_clientes',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => getIt<ClienteBloc>(),
                    child: const CrearClientePage(),
                  ),
                ),
              );
              if (result == true && context.mounted) {
                context.read<ClienteBloc>().add(GetClientesEvent());
              }
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
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
