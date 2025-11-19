import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../productos/domain/entities/producto.dart';
import '../../../clientes/domain/entities/cliente.dart';
import '../../../clientes/presentation/bloc/cliente_bloc.dart';
import '../../../productos/presentation/bloc/producto_bloc.dart';

class CrearFacturaPage extends StatefulWidget {
  const CrearFacturaPage({super.key});

  @override
  State<CrearFacturaPage> createState() => _CrearFacturaPageState();
}

class _CrearFacturaPageState extends State<CrearFacturaPage> {
  final _formKey = GlobalKey<FormState>();
  Cliente? _clienteSeleccionado;
  final List<ItemFacturaTemp> _items = [];

  @override
  void initState() {
    super.initState();
    // Cargar datos reales desde la API
    context.read<ClienteBloc>().add(GetClientesEvent());
    context.read<ProductoBloc>().add(GetProductosEvent());
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Factura'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<ClienteBloc, ClienteState>(
        builder: (context, clienteState) {
          return BlocBuilder<ProductoBloc, ProductoState>(
            builder: (context, productoState) {
              // Mostrar loading si alguno está cargando
              if (clienteState is ClienteLoading ||
                  productoState is ProductoLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Obtener listas desde los estados
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
                            // Selección de Cliente
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'No hay clientes disponibles',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    else
                                      DropdownButtonFormField<Cliente>(
                                        value: _clienteSeleccionado,
                                        decoration: const InputDecoration(
                                          labelText: 'Seleccionar Cliente',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: clientes.map((cliente) {
                                          return DropdownMenuItem(
                                            value: cliente,
                                            child: Text(
                                              '${cliente.nombre} - ${cliente.ruc}',
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (cliente) {
                                          setState(() {
                                            _clienteSeleccionado = cliente;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null) {
                                            return 'Por favor seleccione un cliente';
                                          }
                                          return null;
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Items de la factura
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Items',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: productos.isEmpty
                                              ? null
                                              : () => _agregarItem(productos),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Agregar Item'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_items.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Text(
                                            'No hay items agregados',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _items.length,
                                        itemBuilder: (context, index) {
                                          final item = _items[index];
                                          return Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: ListTile(
                                              title: Text(item.descripcion),
                                              subtitle: Text(
                                                'Cantidad: ${item.cantidad} x \$${item.precioUnitario.toStringAsFixed(2)}',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '\$${item.subtotal.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _items.removeAt(index);
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Total y botones
                    Container(
                      padding: const EdgeInsets.all(16),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_subtotal.toStringAsFixed(2)}',
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
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _guardarFactura,
                                  child: const Text('Guardar Factura'),
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
            content: Text('Debe agregar al menos un item'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // TODO: Aquí llamarías al Bloc para guardar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factura guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}

class ItemFacturaTemp {
  final String descripcion;
  final int cantidad;
  final double precioUnitario;

  ItemFacturaTemp({
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
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
  Producto? _productoSeleccionado;
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Producto>(
              value: _productoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
              items: widget.productos.map((producto) {
                return DropdownMenuItem(
                  value: producto,
                  child: Text('${producto.descripcion} - \$${producto.precio}'),
                );
              }).toList(),
              onChanged: (producto) {
                setState(() {
                  _productoSeleccionado = producto;
                  _precioController.text = producto?.precio.toString() ?? '';
                });
              },
              validator: (value) {
                if (value == null) return 'Seleccione un producto';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese la cantidad';
                }
                final cantidad = int.tryParse(value);
                if (cantidad == null || cantidad <= 0) {
                  return 'Cantidad inválida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio Unitario',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el precio';
                }
                final precio = double.tryParse(value);
                if (precio == null || precio <= 0) {
                  return 'Precio inválido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final item = ItemFacturaTemp(
                descripcion: _productoSeleccionado!.descripcion,
                cantidad: int.parse(_cantidadController.text),
                precioUnitario: double.parse(_precioController.text),
              );
              widget.onAgregar(item);
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
