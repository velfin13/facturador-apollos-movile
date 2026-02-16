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
    context.read<ProductoBloc>().add(
      GetProductosEvent(activo: _activoFromFiltro(_filtro)),
    );
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
      context.read<ProductoBloc>().add(
        GetProductosEvent(activo: _activoFromFiltro(_filtro)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ProductoBloc>()
            ..add(GetProductosEvent(activo: _activoFromFiltro(_filtro))),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Productos'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              PopupMenuButton<_FiltroEstadoProducto>(
                initialValue: _filtro,
                onSelected: (value) {
                  setState(() => _filtro = value);
                  context.read<ProductoBloc>().add(
                    GetProductosEvent(activo: _activoFromFiltro(value)),
                  );
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _FiltroEstadoProducto.todos,
                    child: Text('Todos'),
                  ),
                  PopupMenuItem(
                    value: _FiltroEstadoProducto.activos,
                    child: Text('Solo activos'),
                  ),
                  PopupMenuItem(
                    value: _FiltroEstadoProducto.inactivos,
                    child: Text('Solo inactivos'),
                  ),
                ],
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          body: BlocConsumer<ProductoBloc, ProductoState>(
          listener: (context, state) {
            if (state is ProductoStatusUpdated) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is ProductoLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductoLoaded) {
              return RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: ProductoListWidget(
                  productos: state.productos,
                  onStockAjustado: () {
                    context.read<ProductoBloc>().add(
                      GetProductosEvent(activo: _activoFromFiltro(_filtro)),
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
                    final confirmed = await _confirmarCambioEstado(
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
              );
            } else if (state is ProductoError) {
              return RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${state.message}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<ProductoBloc>().add(
                                  GetProductosEvent(
                                    activo: _activoFromFiltro(_filtro),
                                  ),
                                );
                              },
                              child: const Text('Reintentar'),
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
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_productos',
            onPressed: () async {
              await _abrirFormularioProducto(context: context);
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmarCambioEstado(
    BuildContext context,
    String descripcionProducto,
    bool activar,
  ) async {
    final accion = activar ? 'activar' : 'desactivar';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${activar ? "Activar" : "Desactivar"} producto'),
        content: Text('¿Deseas $accion "$descripcionProducto"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
