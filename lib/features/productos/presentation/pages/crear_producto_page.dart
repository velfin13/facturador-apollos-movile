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

  int? _periodoSeleccionado;
  int? _usuarioSeleccionado;
  String _tipoSeleccionado = 'B';
  int? _impuestoSeleccionado;
  int? _estadoItemSeleccionado;
  bool _aplicaIva = false;
  bool _activo = true;
  static const double _compactFormBreakpoint = 430;

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
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header visual ──────────────────────────────────────
                      _buildHeroHeader(theme),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Información básica ─────────────────────────
                            _buildSectionCard(
                              title: 'Información básica',
                              icon: Icons.info_outline,
                              children: [
                                TextFormField(
                                  controller: _descripcionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción *',
                                    hintText: 'Ej: APRONAX 10MG',
                                    prefixIcon: Icon(Icons.inventory_2),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Ingrese la descripción';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact = constraints.maxWidth <
                                        _compactFormBreakpoint;
                                    final tipoField = _buildDropdown<String>(
                                      label: 'Tipo *',
                                      icon: Icons.category_outlined,
                                      value: _tipoSeleccionado,
                                      items: _tipos,
                                      onChanged: (value) => setState(
                                        () => _tipoSeleccionado = value!,
                                      ),
                                    );
                                    final barraField = TextFormField(
                                      controller: _barraController,
                                      decoration: const InputDecoration(
                                        labelText: 'Código de barras',
                                        prefixIcon: Icon(Icons.qr_code),
                                      ),
                                    );

                                    if (isCompact) {
                                      return Column(
                                        children: [
                                          tipoField,
                                          const SizedBox(height: 12),
                                          barraField,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: tipoField),
                                        const SizedBox(width: 12),
                                        Expanded(child: barraField),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                                _buildReadOnlyField(
                                  label: 'Período del negocio',
                                  icon: Icons.calendar_today_outlined,
                                  value: _periodoSeleccionado?.toString() ??
                                      'No definido',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Precios ────────────────────────────────────
                            _buildSectionCard(
                              title: 'Precios',
                              icon: Icons.attach_money,
                              children: [
                                TextFormField(
                                  controller: _precio1Controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio 1 (Principal) *',
                                    prefixIcon: Icon(Icons.sell),
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
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Ingrese el precio';
                                    }
                                    final precio = double.tryParse(value);
                                    if (precio == null || precio <= 0) {
                                      return 'Precio inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact = constraints.maxWidth <
                                        _compactFormBreakpoint;
                                    final p2 = TextFormField(
                                      controller: _precio2Controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio 2',
                                        prefixIcon:
                                            Icon(Icons.sell_outlined),
                                        prefixText: '\$ ',
                                      ),
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}'),
                                        ),
                                      ],
                                    );
                                    final p3 = TextFormField(
                                      controller: _precio3Controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio 3',
                                        prefixIcon:
                                            Icon(Icons.sell_outlined),
                                        prefixText: '\$ ',
                                      ),
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}'),
                                        ),
                                      ],
                                    );
                                    if (isCompact) {
                                      return Column(
                                        children: [
                                          p2,
                                          const SizedBox(height: 12),
                                          p3,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: p2),
                                        const SizedBox(width: 12),
                                        Expanded(child: p3),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Impuestos y configuración ──────────────────
                            _buildSectionCard(
                              title: 'Impuestos y configuración',
                              icon: Icons.tune,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact = constraints.maxWidth <
                                        _compactFormBreakpoint;
                                    final impuestoField = _buildDropdown<int>(
                                      label: 'Impuesto *',
                                      icon: Icons.receipt_outlined,
                                      value: _impuestoSeleccionado,
                                      items: _impuestos,
                                      onChanged: (value) => setState(
                                        () => _impuestoSeleccionado = value,
                                      ),
                                    );
                                    final estadoField = _buildDropdown<int>(
                                      label: 'Estado *',
                                      icon: Icons.flag_outlined,
                                      value: _estadoItemSeleccionado,
                                      items: _estadosItem,
                                      onChanged: (value) => setState(
                                        () =>
                                            _estadoItemSeleccionado = value,
                                      ),
                                    );
                                    if (isCompact) {
                                      return Column(
                                        children: [
                                          impuestoField,
                                          const SizedBox(height: 12),
                                          estadoField,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: impuestoField),
                                        const SizedBox(width: 12),
                                        Expanded(child: estadoField),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _fraccionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Fracción',
                                    hintText: 'Unidades por paquete',
                                    prefixIcon: Icon(Icons.grid_view),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ── Toggles visuales ──────────────────────
                                _buildToggleCard(
                                  icon: Icons.percent,
                                  title: 'Aplica IVA',
                                  subtitle: 'Este producto grava impuesto',
                                  value: _aplicaIva,
                                  activeColor:
                                      Colors.orange.shade700,
                                  onChanged: (v) =>
                                      setState(() => _aplicaIva = v),
                                ),
                                const SizedBox(height: 10),
                                _buildToggleCard(
                                  icon: Icons.check_circle_outline,
                                  title: 'Producto activo',
                                  subtitle:
                                      'Visible en ventas y catálogo',
                                  value: _activo,
                                  activeColor:
                                      Theme.of(context).colorScheme.primary,
                                  onChanged: (v) =>
                                      setState(() => _activo = v),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero header ─────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(ThemeData theme) {
    final isEditing = widget.producto != null;
    final color = _activo
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final iconData =
        _tipoSeleccionado == 'B' ? Icons.inventory_2 : Icons.design_services;
    final descripcion = _descripcionController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(iconData, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),

          // Nombre + estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? (descripcion.isNotEmpty
                          ? descripcion
                          : widget.producto!.descripcion)
                      : (descripcion.isNotEmpty
                          ? descripcion
                          : 'Nuevo producto'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _HeaderBadge(
                      label: _tipoSeleccionado == 'B' ? 'Bien' : 'Servicio',
                    ),
                    const SizedBox(width: 6),
                    _HeaderBadge(
                      label: _activo ? 'Activo' : 'Inactivo',
                      icon: _activo
                          ? Icons.check_circle
                          : Icons.cancel,
                    ),
                    if (_aplicaIva) ...[
                      const SizedBox(width: 6),
                      const _HeaderBadge(label: 'IVA'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle visual (reemplaza SwitchListTile) ────────────────────────────────
  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    final theme = Theme.of(context);
    final color = activeColor ?? theme.colorScheme.primary;
    final isOn = value;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isOn ? color.withValues(alpha: 0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOn ? color.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
            width: isOn ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isOn
                    ? color.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isOn ? color : theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isOn ? color : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
              activeTrackColor: color.withValues(alpha: 0.4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section card ────────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Dropdown ─────────────────────────────────────────────────────────────────
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
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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

  // ── Campo solo lectura ───────────────────────────────────────────────────────
  Widget _buildReadOnlyField({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  // ── Botones de acción ────────────────────────────────────────────────────────
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final cancel = SizedBox(
            width: compact ? double.infinity : null,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            ),
          );
          final save = SizedBox(
            width: compact ? double.infinity : null,
            child: BlocBuilder<ProductoBloc, ProductoState>(
              builder: (context, state) {
                final isSaving =
                    state is ProductoCreating || state is ProductoUpdating;
                return FilledButton.icon(
                  onPressed: isSaving ? null : _guardarProducto,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
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
                            ? 'Guardar producto'
                            : 'Actualizar producto',
                  ),
                );
              },
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cancel, const SizedBox(height: 10), save],
            );
          }
          return Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: save),
            ],
          );
        },
      ),
    );
  }

  // ── Sync período ─────────────────────────────────────────────────────────────
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

  // ── Guardar ──────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _HeaderBadge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownItem<T> {
  final T value;
  final String label;
  const _DropdownItem({required this.value, required this.label});
}
