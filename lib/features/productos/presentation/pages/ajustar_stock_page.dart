import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/producto.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/periodo_manager.dart';
import '../../../../injection/injection_container.dart';

class AjustarStockPage extends StatefulWidget {
  final Producto producto;

  const AjustarStockPage({super.key, required this.producto});

  @override
  State<AjustarStockPage> createState() => _AjustarStockPageState();
}

class _AjustarStockPageState extends State<AjustarStockPage> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();

  String _tipoAjuste = 'ENTRADA';
  bool _isLoading = false;
  String? _bodegaSeleccionada;
  List<Map<String, dynamic>> _bodegas = [];
  bool _isLoadingBodegas = true;

  @override
  void initState() {
    super.initState();
    _cargarBodegas();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _cargarBodegas() async {
    try {
      final dioClient = getIt<DioClient>();
      final periodoManager = getIt<PeriodoManager>();

      final response = await dioClient.get(
        '/Inventario/bodegas',
        queryParameters: {'periodo': periodoManager.periodoActual},
      );

      if (response.data is Map && response.data['data'] != null) {
        final data = response.data['data'] as List;
        setState(() {
          _bodegas = data.cast<Map<String, dynamic>>();
          // Seleccionar automáticamente si solo hay una bodega
          if (_bodegas.isNotEmpty) {
            _bodegaSeleccionada = _bodegas.first['idSysInBodega'] as String;
          }
          _isLoadingBodegas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBodegas = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar bodegas: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBodegas) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ajustar Stock'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bodegas.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ajustar Stock'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warehouse, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No hay bodegas disponibles'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar Stock'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del producto
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Producto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.producto.descripcion,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Stock Actual:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${widget.producto.stock} unidades',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: widget.producto.stock > 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipo de ajuste
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tipo de Ajuste',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_bodegas.length > 1)
                              DropdownButtonFormField<String>(
                                value: _bodegaSeleccionada,
                                decoration: const InputDecoration(
                                  labelText: 'Bodega',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.warehouse),
                                ),
                                items: _bodegas.map((bodega) {
                                  return DropdownMenuItem(
                                    value: bodega['idSysInBodega'] as String,
                                    child: Text(
                                      '${bodega['idSysInBodega']} (${bodega['cantidadProductos']} productos)',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _bodegaSeleccionada = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Seleccione una bodega';
                                  }
                                  return null;
                                },
                              )
                            else
                              ListTile(
                                leading: const Icon(Icons.warehouse),
                                title: const Text('Bodega'),
                                subtitle: Text(_bodegaSeleccionada ?? 'N/A'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            const SizedBox(height: 16),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'ENTRADA',
                                  label: Text('Entrada'),
                                  icon: Icon(Icons.add_circle_outline),
                                ),
                                ButtonSegment(
                                  value: 'SALIDA',
                                  label: Text('Salida'),
                                  icon: Icon(Icons.remove_circle_outline),
                                ),
                              ],
                              selected: {_tipoAjuste},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _tipoAjuste = newSelection.first;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cantidadController,
                              decoration: InputDecoration(
                                labelText: 'Cantidad *',
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(
                                  _tipoAjuste == 'ENTRADA'
                                      ? Icons.add
                                      : Icons.remove,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese la cantidad';
                                }
                                final cantidad = int.tryParse(value);
                                if (cantidad == null || cantidad <= 0) {
                                  return 'Cantidad inválida';
                                }
                                if (_tipoAjuste == 'SALIDA' &&
                                    cantidad > widget.producto.stock) {
                                  return 'No hay suficiente stock (actual: ${widget.producto.stock})';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _motivoController,
                              decoration: const InputDecoration(
                                labelText: 'Motivo *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                                hintText:
                                    'Ej: Compra, Venta, Ajuste, Daño, etc.',
                              ),
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese el motivo';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resumen
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Stock actual:'),
                                Text(
                                  '${widget.producto.stock}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_tipoAjuste == 'ENTRADA' ? 'Ingreso' : 'Salida'}:',
                                ),
                                Text(
                                  '${_tipoAjuste == 'ENTRADA' ? '+' : '-'}${_cantidadController.text.isEmpty ? '0' : _cantidadController.text}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _tipoAjuste == 'ENTRADA'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Nuevo stock:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _calcularNuevoStock().toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarAjuste,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar Ajuste'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calcularNuevoStock() {
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    if (_tipoAjuste == 'ENTRADA') {
      return widget.producto.stock + cantidad;
    } else {
      return widget.producto.stock - cantidad;
    }
  }

  Future<void> _guardarAjuste() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final dioClient = getIt<DioClient>();
        final periodoManager = getIt<PeriodoManager>();
        final cantidad = int.parse(_cantidadController.text);

        await dioClient.post(
          '/Inventario/ajuste',
          data: {
            'idSysPeriodo': periodoManager.periodoActual,
            'idSysInProducto': widget.producto.id,
            'idSysInBodega':
                _bodegaSeleccionada, // Bodega seleccionada dinámicamente
            'cantidadAjuste': cantidad.toDouble(),
            'tipoAjuste': _tipoAjuste,
            'motivo': _motivoController.text.trim(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock ajustado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // true indica que hubo cambios
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
