import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/producto.dart';
import '../bloc/producto_bloc.dart';

class CrearProductoPage extends StatefulWidget {
  const CrearProductoPage({super.key});

  @override
  State<CrearProductoPage> createState() => _CrearProductoPageState();
}

class _CrearProductoPageState extends State<CrearProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _barraController = TextEditingController();
  final _costoController = TextEditingController();
  final _precio1Controller = TextEditingController();
  final _precio2Controller = TextEditingController();
  final _precio3Controller = TextEditingController();

  String _medidaSeleccionada = 'UND';
  bool _aplicaIva = true;
  bool _activo = true;

  final List<String> _medidas = ['UND', 'KG', 'LT', 'MT', 'CJ', 'PAQ'];

  @override
  void dispose() {
    _descripcionController.dispose();
    _barraController.dispose();
    _costoController.dispose();
    _precio1Controller.dispose();
    _precio2Controller.dispose();
    _precio3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductoBloc, ProductoState>(
      listener: (context, state) {
        if (state is ProductoCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is ProductoError) {
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
          title: const Text('Nuevo Producto'),
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
                      // Información básica
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Información Básica',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descripcionController,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.inventory_2),
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingrese la descripción';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _medidaSeleccionada,
                                      decoration: const InputDecoration(
                                        labelText: 'Unidad de Medida',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.straighten),
                                      ),
                                      items: _medidas.map((medida) {
                                        return DropdownMenuItem(
                                          value: medida,
                                          child: Text(medida),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _medidaSeleccionada = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _barraController,
                                      decoration: const InputDecoration(
                                        labelText: 'Código de Barras',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.qr_code),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Precios
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Precios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _costoController,
                                decoration: const InputDecoration(
                                  labelText: 'Costo',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _precio1Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Precio 1 *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.sell),
                                  helperText: 'Precio principal de venta',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingrese el precio';
                                  }
                                  final precio = double.tryParse(value);
                                  if (precio == null || precio <= 0) {
                                    return 'Precio inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _precio2Controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio 2',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.sell_outlined),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _precio3Controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio 3',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.sell_outlined),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Configuración
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Configuración',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Nota: El stock se gestiona desde el módulo de inventario',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('Aplica IVA (15%)'),
                                subtitle: const Text(
                                  'Marca si este producto tiene IVA',
                                ),
                                value: _aplicaIva,
                                onChanged: (value) {
                                  setState(() {
                                    _aplicaIva = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Producto Activo'),
                                subtitle: const Text(
                                  'Desactiva para ocultar en ventas',
                                ),
                                value: _activo,
                                onChanged: (value) {
                                  setState(() {
                                    _activo = value;
                                  });
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardarProducto,
                        child: const Text('Guardar Producto'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardarProducto() {
    if (_formKey.currentState!.validate()) {
      // El ID lo generará el backend automáticamente
      final producto = Producto(
        id: '', // El backend generará el ID
        periodo: DateTime.now().year.toString(),
        descripcion: _descripcionController.text.trim(),
        medida: _medidaSeleccionada,
        costo: _costoController.text.trim().isEmpty
            ? null
            : double.parse(_costoController.text),
        iva: _aplicaIva ? 'S' : 'N',
        precio1: double.parse(_precio1Controller.text),
        precio2: _precio2Controller.text.trim().isEmpty
            ? null
            : double.parse(_precio2Controller.text),
        precio3: _precio3Controller.text.trim().isEmpty
            ? null
            : double.parse(_precio3Controller.text),
        barra: _barraController.text.trim().isEmpty
            ? null
            : _barraController.text.trim(),
        activo: _activo,
        stock: 0, // El stock se gestiona desde inventario
      );

      context.read<ProductoBloc>().add(CreateProductoEvent(producto));
    }
  }
}
