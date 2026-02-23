import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection/injection_container.dart';
import '../../domain/entities/producto.dart';
import '../bloc/producto_bloc.dart';
import '../widgets/producto_list_widget.dart';
import 'crear_producto_page.dart';

enum _FiltroEstadoProducto { todos, activos, inactivos }

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  _FiltroEstadoProducto _filtro = _FiltroEstadoProducto.todos;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _activoFromFiltro(_FiltroEstadoProducto filtro) {
    switch (filtro) {
      case _FiltroEstadoProducto.activos:
        return 'S';
      case _FiltroEstadoProducto.inactivos:
        return 'N';
      case _FiltroEstadoProducto.todos:
        return '';
    }
  }

  Future<void> _onRefresh(BuildContext context) async {
    context
        .read<ProductoBloc>()
        .add(GetProductosEvent(activo: _activoFromFiltro(_filtro)));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _abrirFormularioProducto({
    required BuildContext context,
    Producto? producto,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ProductoBloc>(),
          child: CrearProductoPage(producto: producto),
        ),
      ),
    );

    if (result == true && context.mounted) {
      context
          .read<ProductoBloc>()
          .add(GetProductosEvent(activo: _activoFromFiltro(_filtro)));
    }
  }

  List<Producto> _filtrarProductos(List<Producto> productos) {
    if (_searchQuery.isEmpty) return productos;
    final q = _searchQuery.toLowerCase();
    return productos.where((p) {
      return p.descripcion.toLowerCase().contains(q) ||
          (p.barra?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) =>
          getIt<ProductoBloc>()
            ..add(GetProductosEvent(activo: _activoFromFiltro(_filtro))),
      child: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Buscar producto o código...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                  onChanged: (value) => setState(() => _searchQuery = value),
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

              // Chips de filtro
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      selected: _filtro == _FiltroEstadoProducto.todos,
                      onTap: () {
                        setState(() => _filtro = _FiltroEstadoProducto.todos);
                        context
                            .read<ProductoBloc>()
                            .add(GetProductosEvent(activo: ''));
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Activos',
                      selected: _filtro == _FiltroEstadoProducto.activos,
                      icon: Icons.check_circle_outline,
                      onTap: () {
                        setState(
                          () => _filtro = _FiltroEstadoProducto.activos,
                        );
                        context
                            .read<ProductoBloc>()
                            .add(GetProductosEvent(activo: 'S'));
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inactivos',
                      selected: _filtro == _FiltroEstadoProducto.inactivos,
                      icon: Icons.visibility_off_outlined,
                      onTap: () {
                        setState(
                          () => _filtro = _FiltroEstadoProducto.inactivos,
                        );
                        context
                            .read<ProductoBloc>()
                            .add(GetProductosEvent(activo: 'N'));
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocConsumer<ProductoBloc, ProductoState>(
                  listener: (context, state) {
                    if (state is ProductoStatusUpdated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is ProductoLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ProductoLoaded) {
                      final filtered = _filtrarProductos(state.productos);
                      return RefreshIndicator(
                        onRefresh: () => _onRefresh(context),
                        child: Column(
                          children: [
                            // Contador
                            if (state.productos.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                                child: Row(
                                  children: [
                                    Text(
                                      '${filtered.length} producto${filtered.length != 1 ? 's' : ''}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_searchQuery.isNotEmpty &&
                                        filtered.length !=
                                            state.productos.length) ...[
                                      Text(
                                        ' de ${state.productos.length}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            Expanded(
                              child: ProductoListWidget(
                                productos: filtered,
                                onStockAjustado: () {
                                  context.read<ProductoBloc>().add(
                                    GetProductosEvent(
                                      activo: _activoFromFiltro(_filtro),
                                    ),
                                  );
                                },
                                onEdit: (producto) async {
                                  await _abrirFormularioProducto(
                                    context: context,
                                    producto: producto,
                                  );
                                },
                                onToggleStatus: (producto) async {
                                  final activar = !producto.estaActivo;
                                  final confirmed =
                                      await _confirmarCambioEstado(
                                        context,
                                        producto.descripcion,
                                        activar,
                                      );
                                  if (!confirmed || !context.mounted) return;

                                  context.read<ProductoBloc>().add(
                                    ToggleProductoStatusEvent(
                                      producto: producto,
                                      activar: activar,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is ProductoError) {
                      return RefreshIndicator(
                        onRefresh: () => _onRefresh(context),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
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
                                      'Error al cargar productos',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                      ),
                                      child: Text(
                                        state.message,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton.icon(
                                      onPressed: () {
                                        context.read<ProductoBloc>().add(
                                          GetProductosEvent(
                                            activo: _activoFromFiltro(_filtro),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Reintentar'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => _onRefresh(context),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: const Center(child: Text('No hay datos')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_productos',
            onPressed: () async {
              await _abrirFormularioProducto(context: context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nuevo producto'),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmarCambioEstado(
    BuildContext context,
    String descripcion,
    bool activar,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          activar ? Icons.check_circle_outline : Icons.visibility_off_outlined,
          size: 40,
          color: activar ? Colors.green.shade600 : Colors.orange.shade700,
        ),
        title: Text(activar ? 'Activar producto' : 'Desactivar producto'),
        content: Text(
          '¿Deseas ${activar ? "activar" : "desactivar"} "$descripcion"?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return result ?? false;
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
