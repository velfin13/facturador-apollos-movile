import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/periodo_manager.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection/injection_container.dart';
import '../../domain/entities/producto.dart';
import '../bloc/producto_bloc.dart';

class CrearProductoPage extends StatefulWidget {
  final Producto? producto;

  const CrearProductoPage({super.key, this.producto});

  @override
  State<CrearProductoPage> createState() => _CrearProductoPageState();
}

class _CrearProductoPageState extends State<CrearProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _barraController = TextEditingController();
  final _precio1Controller = TextEditingController();
  final _precio2Controller = TextEditingController();
  final _precio3Controller = TextEditingController();
  final _fraccionController = TextEditingController();

  // Valores seleccionados
  int? _periodoSeleccionado;
  int? _usuarioSeleccionado;
  String _tipoSeleccionado = 'B';
  int? _impuestoSeleccionado;
  int? _estadoItemSeleccionado;
  bool _aplicaIva = false;
  bool _activo = true;
  static const double _compactFormBreakpoint = 430;

  // Datos quemados para los dropdowns (luego vendrán del backend)
  final List<_DropdownItem<int>> _usuarios = [
    _DropdownItem(value: 1, label: 'Usuario actual'),
  ];

  final List<_DropdownItem<String>> _tipos = [
    _DropdownItem(value: 'B', label: 'Bien'),
    _DropdownItem(value: 'S', label: 'Servicio'),
  ];

  final List<_DropdownItem<int>> _impuestos = [
    _DropdownItem(value: 1, label: 'IVA 15%'),
    _DropdownItem(value: 2, label: 'IVA 0%'),
    _DropdownItem(value: 3, label: 'No aplica'),
  ];

  final List<_DropdownItem<int>> _estadosItem = [
    _DropdownItem(value: 1, label: 'Disponible'),
    _DropdownItem(value: 2, label: 'Agotado'),
    _DropdownItem(value: 3, label: 'Descontinuado'),
  ];

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _periodoSeleccionado =
        int.tryParse(getIt<PeriodoManager>().periodoActual) ?? 1;
    _usuarioSeleccionado = _usuarios.first.value;
    _impuestoSeleccionado = _impuestos.first.value;
    _estadoItemSeleccionado = _estadosItem.first.value;

    if (producto != null) {
      _descripcionController.text = producto.descripcion;
      _barraController.text = producto.barra ?? '';
      _precio1Controller.text = (producto.precio1 ?? 0).toStringAsFixed(2);
      _precio2Controller.text = producto.precio2?.toStringAsFixed(2) ?? '';
      _precio3Controller.text = producto.precio3?.toStringAsFixed(2) ?? '';
      _fraccionController.text = producto.fraccion?.toString() ?? '';

      _periodoSeleccionado = producto.idSysPeriodo ?? _periodoSeleccionado;
      _usuarioSeleccionado = producto.idSysUsuario ?? _usuarioSeleccionado;
      _tipoSeleccionado = producto.tipo ?? _tipoSeleccionado;
      _impuestoSeleccionado = producto.idImpuesto ?? _impuestoSeleccionado;
      _estadoItemSeleccionado =
          producto.idEstadoItem ?? _estadoItemSeleccionado;
      _aplicaIva = producto.iva == 'S';
      _activo = producto.activo == 'S';
    }

    _syncPeriodoFromServer();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _barraController.dispose();
    _precio1Controller.dispose();
    _precio2Controller.dispose();
    _precio3Controller.dispose();
    _fraccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ProductoBloc, ProductoState>(
      listener: (context, state) {
        if (state is ProductoCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Producto creado exitosamente'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is ProductoUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Producto actualizado exitosamente'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is ProductoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.producto == null ? 'Nuevo Producto' : 'Editar Producto',
          ),
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
                      _buildSectionCard(
                        title: 'Informacion Basica',
                        icon: Icons.info_outline,
                        children: [
                          TextFormField(
                            controller: _descripcionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripcion *',
                              hintText: 'Ej: APRONAX 10MG',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory_2),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingrese la descripcion';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth <
                                  _compactFormBreakpoint) {
                                return Column(
                                  children: [
                                    _buildDropdown<String>(
                                      label: 'Tipo *',
                                      icon: Icons.category,
                                      value: _tipoSeleccionado,
                                      items: _tipos,
                                      onChanged: (value) {
                                        setState(
                                          () => _tipoSeleccionado = value!,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _barraController,
                                      decoration: const InputDecoration(
                                        labelText: 'Codigo de Barras',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.qr_code),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown<String>(
                                      label: 'Tipo *',
                                      icon: Icons.category,
                                      value: _tipoSeleccionado,
                                      items: _tipos,
                                      onChanged: (value) {
                                        setState(
                                          () => _tipoSeleccionado = value!,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _barraController,
                                      decoration: const InputDecoration(
                                        labelText: 'Codigo de Barras',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.qr_code),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildReadOnlyField(
                            label: 'Periodo del negocio',
                            icon: Icons.calendar_today,
                            value:
                                _periodoSeleccionado?.toString() ??
                                'No definido',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Precios
                      _buildSectionCard(
                        title: 'Precios',
                        icon: Icons.attach_money,
                        children: [
                          TextFormField(
                            controller: _precio1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Precio 1 (Principal) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.sell),
                              prefixText: '\$ ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
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
                                return 'Precio invalido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth <
                                  _compactFormBreakpoint) {
                                return Column(
                                  children: [
                                    TextFormField(
                                      controller: _precio2Controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio 2',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.sell_outlined),
                                        prefixText: '\$ ',
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
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _precio3Controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio 3',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.sell_outlined),
                                        prefixText: '\$ ',
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
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _precio2Controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio 2',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.sell_outlined),
                                        prefixText: '\$ ',
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _precio3Controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio 3',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.sell_outlined),
                                        prefixText: '\$ ',
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
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Impuestos y configuración
                      _buildSectionCard(
                        title: 'Impuestos y Configuracion',
                        icon: Icons.settings,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth <
                                  _compactFormBreakpoint) {
                                return Column(
                                  children: [
                                    _buildDropdown<int>(
                                      label: 'Impuesto *',
                                      icon: Icons.receipt,
                                      value: _impuestoSeleccionado,
                                      items: _impuestos,
                                      onChanged: (value) {
                                        setState(
                                          () => _impuestoSeleccionado = value,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDropdown<int>(
                                      label: 'Estado *',
                                      icon: Icons.flag,
                                      value: _estadoItemSeleccionado,
                                      items: _estadosItem,
                                      onChanged: (value) {
                                        setState(
                                          () => _estadoItemSeleccionado = value,
                                        );
                                      },
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown<int>(
                                      label: 'Impuesto *',
                                      icon: Icons.receipt,
                                      value: _impuestoSeleccionado,
                                      items: _impuestos,
                                      onChanged: (value) {
                                        setState(
                                          () => _impuestoSeleccionado = value,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDropdown<int>(
                                      label: 'Estado *',
                                      icon: Icons.flag,
                                      value: _estadoItemSeleccionado,
                                      items: _estadosItem,
                                      onChanged: (value) {
                                        setState(
                                          () => _estadoItemSeleccionado = value,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fraccionController,
                            decoration: const InputDecoration(
                              labelText: 'Fraccion',
                              hintText: 'Unidades por paquete',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.grid_view),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Aplica IVA'),
                            subtitle: const Text(
                              'Marcar si este producto grava IVA',
                            ),
                            value: _aplicaIva,
                            onChanged: (value) {
                              setState(() => _aplicaIva = value);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: const Text('Producto Activo'),
                            subtitle: const Text(
                              'Desactivar para ocultar en ventas',
                            ),
                            value: _activo,
                            onChanged: (value) {
                              setState(() => _activo = value);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<_DropdownItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item.value,
          child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      onChanged: onChanged,
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final actionButtons = <Widget>[
            SizedBox(
              width: compact ? double.infinity : null,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
            ),
            SizedBox(
              width: compact ? double.infinity : null,
              child: BlocBuilder<ProductoBloc, ProductoState>(
                builder: (context, state) {
                  final isLoading = state is ProductoCreating;
                  final isUpdating = state is ProductoUpdating;
                  final isSaving = isLoading || isUpdating;
                  return FilledButton.icon(
                    onPressed: isSaving ? null : _guardarProducto,
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      isSaving
                          ? 'Guardando...'
                          : widget.producto == null
                          ? 'Guardar Producto'
                          : 'Actualizar Producto',
                    ),
                  );
                },
              ),
            ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                actionButtons[0],
                const SizedBox(height: 10),
                actionButtons[1],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: actionButtons[0]),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: actionButtons[1]),
            ],
          );
        },
      ),
    );
  }

  Future<void> _syncPeriodoFromServer() async {
    try {
      final response = await getIt<DioClient>().get('/Empresas');
      final payload = response.data;
      if (payload is! Map || payload['data'] is! List) return;

      final empresas = (payload['data'] as List).whereType<Map>().toList();
      if (empresas.isEmpty) return;

      final primeraEmpresa = empresas.first.map(
        (k, v) => MapEntry(k.toString(), v),
      );
      final periodoValue =
          primeraEmpresa['idSysPeriodo'] ?? primeraEmpresa['id_sys_periodo'];

      final periodo = periodoValue is int
          ? periodoValue
          : int.tryParse(periodoValue?.toString() ?? '');

      if (periodo == null || periodo <= 0) return;

      await getIt<PeriodoManager>().setPeriodo(periodo.toString());

      if (!mounted) return;
      setState(() {
        _periodoSeleccionado = periodo;
      });
    } on DioException {
      // Silencioso: mantiene periodo en cache si no se puede consultar.
    } catch (_) {
      // Silencioso: fallback al periodo local.
    }
  }

  void _guardarProducto() {
    if (_formKey.currentState!.validate()) {
      final productoActual = widget.producto;
      final producto = Producto(
        id: productoActual?.id ?? '',
        idSysPeriodo: _periodoSeleccionado,
        descripcion: _descripcionController.text.trim().toUpperCase(),
        iva: _aplicaIva ? 'S' : 'N',
        activo: _activo ? 'S' : 'N',
        idSysUsuario: _usuarioSeleccionado,
        tipo: _tipoSeleccionado,
        idImpuesto: _impuestoSeleccionado,
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
        fraccion: _fraccionController.text.trim().isEmpty
            ? null
            : int.parse(_fraccionController.text),
        idEstadoItem: _estadoItemSeleccionado,
        stock: productoActual?.stock ?? 0,
      );

      if (productoActual == null) {
        context.read<ProductoBloc>().add(CreateProductoEvent(producto));
      } else {
        context.read<ProductoBloc>().add(UpdateProductoEvent(producto));
      }
    }
  }
}

class _DropdownItem<T> {
  final T value;
  final String label;

  const _DropdownItem({required this.value, required this.label});
}
