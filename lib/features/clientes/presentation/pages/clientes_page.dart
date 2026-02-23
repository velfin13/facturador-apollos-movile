import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection/injection_container.dart';
import '../../domain/entities/cliente.dart';
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

  Future<void> _abrirFormulario(
    BuildContext context, {
    Cliente? cliente,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ClienteBloc>(),
          child: CrearClientePage(cliente: cliente),
        ),
      ),
    );

    if (result == true && context.mounted) {
      context.read<ClienteBloc>().add(GetClientesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => getIt<ClienteBloc>()..add(GetClientesEvent()),
      child: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              // ── Buscador ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Buscar por nombre, RUC, ciudad...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<ClienteBloc>()
                              .add(SearchClientesEvent(''));
                          setState(() {});
                        },
                      ),
                  ],
                  onChanged: (v) => _onSearchChanged(context, v),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerLow,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // ── Filtros ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      selected: _filtro == _FiltroEstadoCliente.todos,
                      onTap: () => _applyStatusFilter(
                        context,
                        _FiltroEstadoCliente.todos,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Activos',
                      icon: Icons.check_circle_outline,
                      selected: _filtro == _FiltroEstadoCliente.activos,
                      onTap: () => _applyStatusFilter(
                        context,
                        _FiltroEstadoCliente.activos,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inactivos',
                      icon: Icons.cancel_outlined,
                      selected: _filtro == _FiltroEstadoCliente.inactivos,
                      onTap: () => _applyStatusFilter(
                        context,
                        _FiltroEstadoCliente.inactivos,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Lista ─────────────────────────────────────────────────────
              Expanded(
                child: BlocConsumer<ClienteBloc, ClienteState>(
                  listenWhen: (_, curr) =>
                      curr is ClienteUpdated || curr is ClienteError,
                  listener: (context, state) {
                    if (state is ClienteUpdated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cliente actualizado'),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    if (state is ClienteError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  buildWhen: (prev, curr) =>
                      curr is ClienteLoading ||
                      curr is ClienteLoaded ||
                      curr is ClienteError,
                  builder: (context, state) {
                    if (state is ClienteLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ClienteLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async =>
                            context.read<ClienteBloc>().add(GetClientesEvent()),
                        child: ClienteListWidget(
                          clientes: state.clientes,
                          hasMore: state.hasMore,
                          total: state.total,
                          onLoadMore: () => context
                              .read<ClienteBloc>()
                              .add(LoadMoreClientesEvent()),
                          onEdit: (cliente) =>
                              _abrirFormulario(context, cliente: cliente),
                        ),
                      );
                    }

                    if (state is ClienteError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 36,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar clientes',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => context
                                  .read<ClienteBloc>()
                                  .add(GetClientesEvent()),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
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
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_clientes',
            onPressed: () => _abrirFormulario(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo cliente'),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
