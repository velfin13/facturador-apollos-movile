import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../productos/domain/entities/producto.dart';
import '../../../clientes/domain/entities/cliente.dart';
import '../../../clientes/presentation/bloc/cliente_bloc.dart';
import '../../../productos/presentation/bloc/producto_bloc.dart';
import '../../domain/entities/factura.dart';
import '../bloc/factura_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection/injection_container.dart';

class _FormaPago {
  final int id;
  final String descripcion;
  const _FormaPago(this.id, this.descripcion);
}

class CrearFacturaPage extends StatefulWidget {
  const CrearFacturaPage({super.key});

  @override
  State<CrearFacturaPage> createState() => _CrearFacturaPageState();
}

class _CrearFacturaPageState extends State<CrearFacturaPage> {
  final _formKey = GlobalKey<FormState>();
  Cliente? _clienteSeleccionado;
  final List<ItemFacturaTemp> _items = [];
  final _observacionController = TextEditingController();

  List<_FormaPago> _formasPago = [];
  _FormaPago? _formaPagoSeleccionada;
  bool _loadingFormasPago = true;

  @override
  void initState() {
    super.initState();
    context.read<ClienteBloc>().add(GetClientesEvent());
    context.read<ProductoBloc>().add(GetProductosEvent());
    _cargarFormasPago();
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarFormasPago() async {
    try {
      final response = await getIt<DioClient>().get(
        '/Ventas/formas-pago',
        queryParameters: {'periodo': 1},
      );
      if (response.data is Map && response.data['data'] is List) {
        final lista = (response.data['data'] as List).map((e) {
          return _FormaPago(
            (e['idSysFcFormaPago'] as num).toInt(),
            (e['descripcion'] ?? 'Sin nombre').toString(),
          );
        }).toList();
        if (mounted) {
          setState(() {
            _formasPago = lista;
            _formaPagoSeleccionada = lista.isNotEmpty ? lista.first : null;
            _loadingFormasPago = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingFormasPago = false);
      }
    } catch (_) {
      // Fallback: formas de pago conocidas
      if (mounted) {
        setState(() {
          _formasPago = const [
            _FormaPago(1, 'EFECTIVO'),
            _FormaPago(2, 'CREDITO'),
          ];
          _formaPagoSeleccionada = const _FormaPago(1, 'EFECTIVO');
          _loadingFormasPago = false;
        });
      }
    }
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get _ivaTotal {
    return _items.fold(0.0, (sum, item) => sum + item.iva);
  }

  double get _total {
    return _subtotal + _ivaTotal;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FacturaBloc, FacturaState>(
      listener: (context, state) {
        if (state is FacturaCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factura guardada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _clienteSeleccionado = null;
            _items.clear();
            _observacionController.clear();
            _formaPagoSeleccionada =
                _formasPago.isNotEmpty ? _formasPago.first : null;
          });
        } else if (state is FacturaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva Factura'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: BlocBuilder<ClienteBloc, ClienteState>(
          builder: (context, clienteState) {
            return BlocBuilder<ProductoBloc, ProductoState>(
              builder: (context, productoState) {
                if (clienteState is ClienteLoading ||
                    productoState is ProductoLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clientes = clienteState is ClienteLoaded
                    ? clienteState.clientes
                    : <Cliente>[];
                final productos = productoState is ProductoLoaded
                    ? productoState.productos
                    : <Producto>[];

                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cliente
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cliente',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (clientes.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'No hay clientes disponibles',
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                        )
                                      else
                                        DropdownButtonFormField<Cliente>(
                                          value: _clienteSeleccionado,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Seleccionar Cliente',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: clientes.map((c) {
                                            return DropdownMenuItem(
                                              value: c,
                                              child: Text(
                                                '${c.nombre} - ${c.ruc}',
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (c) => setState(
                                            () => _clienteSeleccionado = c,
                                          ),
                                          validator: (v) => v == null
                                              ? 'Seleccione un cliente'
                                              : null,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Items
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Productos',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: productos.isEmpty
                                                ? null
                                                : () =>
                                                    _agregarItem(productos),
                                            icon: const Icon(Icons.add),
                                            label: const Text('Agregar'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (_items.isEmpty)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24),
                                            child: Text(
                                              'No hay productos agregados',
                                              style: TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ),
                                        )
                                      else
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _items.length,
                                          itemBuilder: (ctx, i) {
                                            final item = _items[i];
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(
                                                item.descripcion,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              subtitle: Text(
                                                '${item.cantidad} x \$${item.precioUnitario.toStringAsFixed(2)}'
                                                '${item.aplicaIva ? ' + IVA' : ''}',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '\$${item.total.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 20),
                                                    onPressed: () =>
                                                        setState(() {
                                                      _items.removeAt(i);
                                                    }),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Forma de pago
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Forma de Pago',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (_loadingFormasPago)
                                        const Center(
                                          child: SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        )
                                      else
                                        DropdownButtonFormField<_FormaPago>(
                                          value: _formaPagoSeleccionada,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Seleccionar Forma de Pago',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: _formasPago.map((fp) {
                                            return DropdownMenuItem(
                                              value: fp,
                                              child: Text(fp.descripcion),
                                            );
                                          }).toList(),
                                          onChanged: (fp) => setState(
                                            () => _formaPagoSeleccionada = fp,
                                          ),
                                          validator: (v) => v == null
                                              ? 'Seleccione una forma de pago'
                                              : null,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Observación
                              TextFormField(
                                controller: _observacionController,
                                decoration: const InputDecoration(
                                  labelText: 'Observación (opcional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.notes),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Totales y botones
                      Container(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom:
                              16 + MediaQuery.of(context).padding.bottom,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text(
                                  '\$${_subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (_ivaTotal > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('IVA (15%):'),
                                  Text(
                                    '\$${_ivaTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${_total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: BlocBuilder<FacturaBloc,
                                      FacturaState>(
                                    builder: (ctx, state) {
                                      final saving =
                                          state is FacturaCreating;
                                      return ElevatedButton(
                                        onPressed:
                                            saving ? null : _guardarFactura,
                                        child: saving
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white),
                                              )
                                            : const Text('Guardar Factura'),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _agregarItem(List<Producto> productos) {
    showDialog(
      context: context,
      builder: (context) => _AgregarItemDialog(
        productos: productos,
        onAgregar: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  void _guardarFactura() {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe agregar al menos un producto'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final itemsFactura = _items.map((item) {
        return ItemFactura(
          productoId: item.productoId,
          productoNombre: item.descripcion,
          cantidad: item.cantidad.toDouble(),
          valor: item.precioUnitario,
          descuentoPorcentaje: null,
          bodegaId: '0',
        );
      }).toList();

      final formasPago = [
        FormaPago(
          formaPagoId: (_formaPagoSeleccionada?.id ?? 1).toString(),
          formaPagoNombre: _formaPagoSeleccionada?.descripcion,
          valor: _total,
          numero: null,
          referencia: null,
          fechaVence: null,
        ),
      ];

      final factura = Factura(
        id: '',
        periodo: '',
        tipo: 'FV',
        fecha: DateTime.now(),
        clienteId: _clienteSeleccionado!.id,
        clienteNombre: _clienteSeleccionado!.nombre,
        numFact: null,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        subtotal: _subtotal,
        ivaTotal: _ivaTotal,
        descTotal: 0.0,
        total: _total,
        items: itemsFactura,
        formasPago: formasPago,
      );

      context.read<FacturaBloc>().add(CreateFacturaEvent(factura));
    }
  }
}

class ItemFacturaTemp {
  final String productoId;
  final String descripcion;
  final int cantidad;
  final double precioUnitario;
  final bool aplicaIva;

  ItemFacturaTemp({
    required this.productoId,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.aplicaIva,
  });

  double get subtotal => cantidad * precioUnitario;
  double get iva => aplicaIva ? subtotal * 0.15 : 0.0;
  double get total => subtotal + iva;
}

class _AgregarItemDialog extends StatefulWidget {
  final List<Producto> productos;
  final Function(ItemFacturaTemp) onAgregar;

  const _AgregarItemDialog({required this.productos, required this.onAgregar});

  @override
  State<_AgregarItemDialog> createState() => _AgregarItemDialogState();
}

class _AgregarItemDialogState extends State<_AgregarItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  Producto? _productoSeleccionado;
  List<Producto> _productosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _productosFiltrados = widget.productos;
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrar);
    _searchController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _productosFiltrados = widget.productos
          .where((p) =>
              p.descripcion.toLowerCase().contains(q) ||
              (p.barra ?? '').toLowerCase().contains(q))
          .toList();
    });
  }

  void _seleccionarProducto(Producto p) {
    setState(() {
      _productoSeleccionado = p;
      _precioController.text = p.precio.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agregar Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Buscador
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar producto...',
                    hintText: 'Nombre o código de barras',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),

                // Producto seleccionado
                if (_productoSeleccionado != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _productoSeleccionado!.descripcion,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              setState(() => _productoSeleccionado = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Lista de resultados
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _productosFiltrados.length > 8
                        ? 8
                        : _productosFiltrados.length,
                    itemBuilder: (ctx, i) {
                      final p = _productosFiltrados[i];
                      final selected = _productoSeleccionado?.id == p.id;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: Colors.blue.withOpacity(0.1),
                        title: Text(p.descripcion,
                            style:
                                const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          '\$${p.precio.toStringAsFixed(2)}'
                          '${p.tieneIva ? ' + IVA' : ''}'
                          '${p.barra != null ? ' | ${p.barra}' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => _seleccionarProducto(p),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Cantidad y precio
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _precioController,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                          isDense: true,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          final n = double.tryParse(v);
                          if (n == null || n <= 0) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_productoSeleccionado == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seleccione un producto'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        if (_formKey.currentState!.validate()) {
                          widget.onAgregar(ItemFacturaTemp(
                            productoId: _productoSeleccionado!.id,
                            descripcion: _productoSeleccionado!.descripcion,
                            cantidad:
                                int.parse(_cantidadController.text),
                            precioUnitario:
                                double.parse(_precioController.text),
                            aplicaIva: _productoSeleccionado!.tieneIva,
                          ));
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Agregar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
