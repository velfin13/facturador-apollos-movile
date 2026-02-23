import 'dart:async';
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
import '../../../../core/network/periodo_manager.dart';
import '../../../../injection/injection_container.dart';

class _FormaPago {
  final int id;
  final String descripcion;
  final bool esDefault;
  const _FormaPago(this.id, this.descripcion, {this.esDefault = false});
}

// ─────────────────────────────────────────────────────────────────────────────

class CrearFacturaPage extends StatefulWidget {
  const CrearFacturaPage({super.key});

  @override
  State<CrearFacturaPage> createState() => _CrearFacturaPageState();
}

class _CrearFacturaPageState extends State<CrearFacturaPage> {
  Cliente? _clienteSeleccionado;
  bool _clienteError = false;
  DateTime _fecha = DateTime.now();
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
        queryParameters: {'periodo': getIt<PeriodoManager>().periodoActual},
      );
      if (response.data is Map && response.data['data'] is List) {
        final lista = (response.data['data'] as List).map((e) {
          return _FormaPago(
            (e['idSysFcFormaPago'] as num).toInt(),
            (e['descripcion'] ?? 'Sin nombre').toString(),
            // el campo puede llamarse esDefault, esPorDefecto, esPredet…
            esDefault: (e['esDefault'] ?? e['esPorDefecto'] ?? false) == true,
          );
        }).toList();
        if (mounted) {
          if (lista.isNotEmpty) {
            // Busca el marcado como default; si ninguno, usa el primero
            final porDefecto =
                lista.firstWhere((f) => f.esDefault, orElse: () => lista.first);
            setState(() {
              _formasPago = lista;
              _formaPagoSeleccionada = porDefecto;
              _loadingFormasPago = false;
            });
          } else {
            _usarFormasPagoFallback();
          }
        }
      } else {
        if (mounted) _usarFormasPagoFallback();
      }
    } catch (_) {
      if (mounted) _usarFormasPagoFallback();
    }
  }

  void _usarFormasPagoFallback() {
    const efectivo = _FormaPago(1, 'EFECTIVO', esDefault: true);
    setState(() {
      _formasPago = const [
        efectivo,
        _FormaPago(2, 'CREDITO'),
        _FormaPago(3, 'TARJETA DE CRÉDITO'),
        _FormaPago(4, 'TARJETA DE DÉBITO'),
        _FormaPago(5, 'TRANSFERENCIA BANCARIA'),
      ];
      _formaPagoSeleccionada = efectivo;
      _loadingFormasPago = false;
    });
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.subtotal);
  double get _ivaTotal => _items.fold(0.0, (s, i) => s + i.iva);
  double get _total => _subtotal + _ivaTotal;

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _seleccionarCliente() async {
    // Capture the bloc reference before the async gap
    final clienteBloc = context.read<ClienteBloc>();
    final result = await showModalBottomSheet<Cliente>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: clienteBloc,
        child: const _ClienteSelectorSheet(),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _clienteSeleccionado = result;
        _clienteError = false;
      });
    }
  }

  Future<void> _agregarItem({int? editIndex}) async {
    final productoBloc = context.read<ProductoBloc>();
    final item = editIndex != null ? _items[editIndex] : null;
    final result = await showModalBottomSheet<ItemFacturaTemp>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: productoBloc,
        child: _AgregarItemSheet(itemExistente: item),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (editIndex != null) {
          _items[editIndex] = result;
        } else {
          _items.add(result);
        }
      });
    }
  }

  void _guardarFactura() {
    bool hasError = false;
    if (_clienteSeleccionado == null) {
      setState(() => _clienteError = true);
      hasError = true;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debe agregar al menos un producto'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      hasError = true;
    }
    if (hasError) return;

    final itemsFactura = _items
        .map(
          (item) => ItemFactura(
            productoId: item.productoId,
            productoNombre: item.descripcion,
            cantidad: item.cantidad.toDouble(),
            valor: item.precioUnitario,
            descuentoPorcentaje: null,
            bodegaId: '0',
          ),
        )
        .toList();

    final factura = Factura(
      id: '',
      periodo: '',
      tipo: 'FV',
      fecha: _fecha,
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
      formasPago: [
        FormaPago(
          formaPagoId: (_formaPagoSeleccionada?.id ?? 1).toString(),
          formaPagoNombre: _formaPagoSeleccionada?.descripcion,
          valor: _total,
          numero: null,
          referencia: null,
          fechaVence: null,
        ),
      ],
    );

    context.read<FacturaBloc>().add(CreateFacturaEvent(factura));
  }

  IconData _iconForFormaPago(String desc) {
    final d = desc.toUpperCase();
    if (d.contains('EFECTIVO')) return Icons.payments_outlined;
    if (d.contains('TARJETA')) return Icons.credit_card_outlined;
    if (d.contains('TRANSFER')) return Icons.account_balance_outlined;
    if (d.contains('CRÉDIT') || d.contains('CREDITO')) {
      return Icons.receipt_long_outlined;
    }
    if (d.contains('CHEQUE')) return Icons.edit_note_outlined;
    return Icons.attach_money;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<FacturaBloc, FacturaState>(
      listener: (context, state) {
        if (state is FacturaCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Factura emitida exitosamente'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _clienteSeleccionado = null;
            _clienteError = false;
            _fecha = DateTime.now();
            _items.clear();
            _observacionController.clear();
            _formaPagoSeleccionada =
                _formasPago.isNotEmpty ? _formasPago.first : null;
          });
        } else if (state is FacturaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva Factura'),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  '${_fecha.day.toString().padLeft(2, '0')}/'
                  '${_fecha.month.toString().padLeft(2, '0')}/'
                  '${_fecha.year}',
                  style: const TextStyle(fontSize: 13),
                ),
                onPressed: _seleccionarFecha,
              ),
            ),
          ],
        ),
        body: BlocBuilder<ProductoBloc, ProductoState>(
          builder: (context, productoState) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Cliente ───────────────────────────────────────────
                        _buildClienteSection(context, theme),
                        const SizedBox(height: 12),

                        // ── Productos ─────────────────────────────────────────
                        _buildProductosSection(
                          context,
                          theme,
                          productoState,
                        ),
                        const SizedBox(height: 12),

                        // ── Forma de Pago ─────────────────────────────────────
                        _buildFormaPagoSection(theme),
                        const SizedBox(height: 12),

                        // ── Observación ───────────────────────────────────────
                        _buildObservacionSection(theme),
                      ],
                    ),
                  ),
                ),

                // ── Totales + Emitir ──────────────────────────────────────────
                _buildTotalesBar(context, theme),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Builders ────────────────────────────────────────────────────────────────

  Widget _buildClienteSection(BuildContext context, ThemeData theme) {
    return _SectionCard(
      icon: Icons.person_outline,
      title: 'Cliente',
      errorText: _clienteError ? 'Seleccione un cliente' : null,
      child: BlocBuilder<ClienteBloc, ClienteState>(
        builder: (context, clienteState) {
          final loading = clienteState is ClienteLoading;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: _clienteError
                    ? theme.colorScheme.error
                    : _clienteSeleccionado != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                width:
                    (_clienteSeleccionado != null || _clienteError) ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _clienteSeleccionado != null
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                  : theme.colorScheme.surfaceContainerLow,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: loading ? null : _seleccionarCliente,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: loading
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Cargando clientes...'),
                        ],
                      )
                    : _clienteSeleccionado != null
                        ? Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  _clienteSeleccionado!.nombre.isNotEmpty
                                      ? _clienteSeleccionado!.nombre[0]
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _clienteSeleccionado!.nombre,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _clienteSeleccionado!.ruc,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.swap_horiz,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 20,
                                color: _clienteError
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Buscar y seleccionar cliente...',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _clienteError
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductosSection(
    BuildContext context,
    ThemeData theme,
    ProductoState productoState,
  ) {
    final loading = productoState is ProductoLoading;

    return _SectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Productos',
      action: FilledButton.tonalIcon(
        onPressed: loading ? null : () => _agregarItem(),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar'),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      child: _items.isEmpty
          ? Container(
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_shopping_cart_outlined,
                      size: 26,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Presiona Agregar para añadir productos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: List.generate(
                _items.length,
                (i) => _ItemCard(
                  item: _items[i],
                  onEdit: () => _agregarItem(editIndex: i),
                  onDelete: () => setState(() => _items.removeAt(i)),
                ),
              ),
            ),
    );
  }

  Widget _buildFormaPagoSection(ThemeData theme) {
    return _SectionCard(
      icon: Icons.payments_outlined,
      title: 'Forma de Pago',
      child: _loadingFormasPago
          ? Container(
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : DropdownButtonHideUnderline(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: DropdownButton<_FormaPago>(
                  value: _formaPagoSeleccionada,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  icon: Icon(
                    Icons.expand_more_rounded,
                    color: theme.colorScheme.outline,
                  ),
                  // Ítem seleccionado visible en el campo
                  selectedItemBuilder: (ctx) => _formasPago.map((fp) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _iconForFormaPago(fp.descripcion),
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              fp.descripcion,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (fp.esDefault)
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Por defecto',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  // Ítems del menú desplegable
                  items: _formasPago.map((fp) {
                    final isSelected = _formaPagoSeleccionada?.id == fp.id;
                    return DropdownMenuItem<_FormaPago>(
                      value: fp,
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              _iconForFormaPago(fp.descripcion),
                              size: 17,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fp.descripcion,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (fp.esDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Defecto',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (fp) {
                    if (fp != null) setState(() => _formaPagoSeleccionada = fp);
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildObservacionSection(ThemeData theme) {
    return _SectionCard(
      icon: Icons.notes_outlined,
      title: 'Observación',
      child: TextField(
        controller: _observacionController,
        maxLines: 2,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Opcional...',
          hintStyle: TextStyle(color: theme.colorScheme.outline),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildTotalesBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                '\$${_subtotal.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          if (_ivaTotal > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'IVA (15%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  '\$${_ivaTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BlocBuilder<FacturaBloc, FacturaState>(
                  builder: (ctx, state) {
                    final saving = state is FacturaCreating;
                    return FilledButton.icon(
                      onPressed: saving ? null : _guardarFactura,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.receipt_long_outlined, size: 20),
                      label: Text(
                        saving ? 'Emitiendo...' : 'Emitir Factura',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionCard
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? action;
  final String? errorText;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.action,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (action != null) ...[
              const Spacer(),
              action!,
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ItemCard
// ─────────────────────────────────────────────────────────────────────────────

enum _ItemAction { edit, delete }

class _ItemCard extends StatelessWidget {
  final ItemFacturaTemp item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            // Accent bar
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.descripcion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${item.cantidad} × \$${item.precioUnitario.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (item.aplicaIva) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'IVA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '\$${item.total.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            PopupMenuButton<_ItemAction>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: theme.colorScheme.outline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: _ItemAction.edit,
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Editar',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _ItemAction.delete,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (action) {
                if (action == _ItemAction.edit) onEdit();
                if (action == _ItemAction.delete) onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClienteSelectorSheet — uses the ClienteBloc for search + pagination
// Designed for thousands of clients: search dispatched to bloc with debounce,
// load-more on scroll end.
// ─────────────────────────────────────────────────────────────────────────────

class _ClienteSelectorSheet extends StatefulWidget {
  const _ClienteSelectorSheet();

  @override
  State<_ClienteSelectorSheet> createState() => _ClienteSelectorSheetState();
}

class _ClienteSelectorSheetState extends State<_ClienteSelectorSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  // Save the bloc reference early; context may not be valid in dispose()
  late final ClienteBloc _clienteBloc;

  @override
  void initState() {
    super.initState();
    _clienteBloc = context.read<ClienteBloc>();
    // Reset any active search so the list shows all clients
    _clienteBloc.add(SearchClientesEvent(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    // Reset search so the main page is unaffected after closing
    _clienteBloc.add(SearchClientesEvent(''));
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _clienteBloc.add(SearchClientesEvent(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: BlocBuilder<ClienteBloc, ClienteState>(
              builder: (context, state) {
                final total = state is ClienteLoaded ? state.total : 0;
                final showing =
                    state is ClienteLoaded ? state.clientes.length : 0;
                return Row(
                  children: [
                    Text(
                      'Seleccionar Cliente',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (total > 0)
                      Text(
                        '$showing de $total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // SearchBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
              onChanged: (v) {
                setState(() {});
                _onSearch(v);
              },
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
          const SizedBox(height: 8),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          // List
          Expanded(
            child: BlocBuilder<ClienteBloc, ClienteState>(
              builder: (context, state) {
                if (state is ClienteLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ClienteLoaded) {
                  final clientes = state.clientes;
                  if (clientes.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin resultados',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          notification.metrics.extentAfter < 200 &&
                          state.hasMore) {
                        context
                            .read<ClienteBloc>()
                            .add(LoadMoreClientesEvent());
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: clientes.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == clientes.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final c = clientes[i];
                        final initial = c.nombre.isNotEmpty
                            ? c.nombre[0].toUpperCase()
                            : '?';
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(
                            c.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            c.ruc +
                                (c.ciudad?.isNotEmpty == true
                                    ? ' · ${c.ciudad}'
                                    : ''),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AgregarItemSheet — product add / edit bottom sheet
// Uses server-side search via ProductoBloc with debounce + load-more on scroll.
// ─────────────────────────────────────────────────────────────────────────────

class _AgregarItemSheet extends StatefulWidget {
  final ItemFacturaTemp? itemExistente;

  const _AgregarItemSheet({this.itemExistente});

  @override
  State<_AgregarItemSheet> createState() => _AgregarItemSheetState();
}

class _AgregarItemSheetState extends State<_AgregarItemSheet> {
  final _searchController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  Producto? _productoSeleccionado;
  Timer? _debounce;
  late final ProductoBloc _productoBloc;

  @override
  void initState() {
    super.initState();
    _productoBloc = context.read<ProductoBloc>();
    final item = widget.itemExistente;
    if (item != null) {
      _cantidadController.text = item.cantidad.toString();
      _precioController.text = item.precioUnitario.toStringAsFixed(2);
      _searchController.text = item.descripcion;
      _productoBloc.add(SearchProductosEvent(item.descripcion));
    } else {
      _productoBloc.add(GetProductosEvent());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _productoBloc.add(GetProductosEvent());
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _productoBloc.add(SearchProductosEvent(value)),
    );
  }

  void _seleccionarProducto(Producto p) {
    setState(() {
      _productoSeleccionado = p;
      _precioController.text = p.precio.toStringAsFixed(2);
    });
  }

  void _confirmar() {
    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Seleccione un producto'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final cant = int.tryParse(_cantidadController.text);
    final precio = double.tryParse(_precioController.text);
    if (cant == null || cant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cantidad inválida'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Precio inválido'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      ItemFacturaTemp(
        productoId: _productoSeleccionado!.id,
        descripcion: _productoSeleccionado!.descripcion,
        cantidad: cant,
        precioUnitario: precio,
        aplicaIva: _productoSeleccionado!.tieneIva,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.itemExistente != null;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: BlocBuilder<ProductoBloc, ProductoState>(
                builder: (context, state) {
                  final total = state is ProductoLoaded ? state.total : 0;
                  final showing =
                      state is ProductoLoaded ? state.productos.length : 0;
                  return Row(
                    children: [
                      Text(
                        isEdit ? 'Editar Producto' : 'Agregar Producto',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_productoSeleccionado == null && total > 0)
                        Text(
                          '$showing de $total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // SearchBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Buscar por nombre o código de barras...',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _productoSeleccionado = null);
                        _productoBloc.add(GetProductosEvent());
                      },
                    ),
                ],
                onChanged: (v) {
                  setState(() {});
                  _onSearch(v);
                },
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
            const SizedBox(height: 8),

            // Selected product preview
            if (_productoSeleccionado != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _productoSeleccionado!.descripcion,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  '\$${_productoSeleccionado!.precio.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                if (_productoSeleccionado!.tieneIva) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'IVA 15%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _productoSeleccionado = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),

            Divider(height: 1, color: theme.colorScheme.outlineVariant),

            // Product list — server-side search + load more on scroll
            Expanded(
              child: BlocBuilder<ProductoBloc, ProductoState>(
                builder: (context, state) {
                  if (state is ProductoLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ProductoLoaded) {
                    final productos = state.productos;

                    // Auto-select in edit mode when product is found in list
                    if (_productoSeleccionado == null &&
                        widget.itemExistente != null) {
                      final match = productos
                          .where(
                              (p) => p.id == widget.itemExistente!.productoId)
                          .firstOrNull;
                      if (match != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _productoSeleccionado = match);
                        });
                      }
                    }

                    if (productos.isEmpty) {
                      return Center(
                        child: Text(
                          'Sin resultados',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            notification.metrics.extentAfter < 200 &&
                            state.hasMore) {
                          context
                              .read<ProductoBloc>()
                              .add(LoadMoreProductosEvent());
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: productos.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == productos.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final p = productos[i];
                          final selected = _productoSeleccionado?.id == p.id;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor: theme
                                .colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            leading: selected
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.circle_outlined,
                                    color: theme.colorScheme.outlineVariant,
                                    size: 20,
                                  ),
                            title: Text(
                              p.descripcion,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '\$${p.precio.toStringAsFixed(2)}'
                              '${p.tieneIva ? ' + IVA' : ''}'
                              '${p.barra != null ? ' · ${p.barra}' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => _seleccionarProducto(p),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Bottom bar: qty / price / confirm
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 16 + mediaQuery.padding.bottom),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cantidad
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Cant.',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Precio
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _precioController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Confirm button
                  Expanded(
                    child: FilledButton(
                      onPressed: _confirmar,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        isEdit ? 'Guardar' : 'Agregar',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────

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
