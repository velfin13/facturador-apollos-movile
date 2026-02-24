import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/factura.dart';
import '../bloc/factura_bloc.dart';

final _fmt = NumberFormat('#,##0.00', 'es');

// ─────────────────────────────────────────────────────────────────────────────
// Lista principal
// ─────────────────────────────────────────────────────────────────────────────

class FacturaListWidget extends StatelessWidget {
  final List<Factura> facturas;
  final bool hasMore;
  final int total;
  final VoidCallback? onLoadMore;

  const FacturaListWidget({
    super.key,
    required this.facturas,
    this.hasMore = false,
    this.total = 0,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (facturas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No hay facturas disponibles',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.extentAfter < 200 &&
            hasMore) {
          onLoadMore?.call();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: facturas.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
              child: Text(
                'Mostrando ${facturas.length} de $total facturas',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            );
          }

          final i = index - 1;

          if (i == facturas.length) {
            return hasMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          final factura = facturas[i];
          return _FacturaCard(
            factura: factura,
            onTap: () => _openDetalle(context, factura),
          );
        },
      ),
    );
  }

  void _openDetalle(BuildContext outerContext, Factura factura) {
    final bloc = outerContext.read<FacturaBloc>();
    bloc.add(GetFacturaDetailsEvent(factura.id));

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) => _DetalleSheet(
            factura: factura,
            scrollController: controller,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de la lista
// ─────────────────────────────────────────────────────────────────────────────

class _FacturaCard extends StatelessWidget {
  final Factura factura;
  final VoidCallback onTap;

  const _FacturaCard({required this.factura, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.receipt_long, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      factura.numFact ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      factura.clienteNombre ?? factura.clienteId,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd/MM/yyyy').format(factura.fecha),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${_fmt.format(factura.total)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet de detalle
// ─────────────────────────────────────────────────────────────────────────────

class _DetalleSheet extends StatelessWidget {
  final Factura factura;
  final ScrollController scrollController;

  const _DetalleSheet(
      {required this.factura, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<FacturaBloc, FacturaState>(
              buildWhen: (p, c) =>
                  c is FacturaDetailsLoaded || c is FacturaError,
              builder: (_, state) {
                final detalle = state is FacturaDetailsLoaded &&
                        state.factura.id == factura.id
                    ? state.factura
                    : null;

                return CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // ── Cabecera ──────────────────────────────────────────
                    SliverToBoxAdapter(
                        child: _Header(factura: factura)),

                    // ── Título sección productos ──────────────────────────
                    SliverToBoxAdapter(
                      child: _SectionTitle(
                        icon: Icons.inventory_2_outlined,
                        label: 'Productos',
                        badge: detalle?.items.length,
                      ),
                    ),

                    // ── Items (virtualizados con SliverList) ──────────────
                    if (detalle == null)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    else if (detalle.items.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('Sin productos registrados'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _ItemRow(
                                item: detalle.items[i], index: i),
                            childCount: detalle.items.length,
                          ),
                        ),
                      ),

                    // ── Totales ───────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _Totales(factura: detalle ?? factura),
                    ),

                    // ── Formas de pago ────────────────────────────────────
                    if ((detalle ?? factura).formasPago.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _FormasPago(
                            formasPago: (detalle ?? factura).formasPago),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabecera del detalle
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Factura factura;
  const _Header({required this.factura});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.25),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            factura.numFact ?? factura.id,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_outline,
            text: factura.clienteNombre ?? factura.clienteId,
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: DateFormat('dd/MM/yyyy').format(factura.fecha),
          ),
          if (factura.observacion != null &&
              factura.observacion!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(
                icon: Icons.notes_outlined, text: factura.observacion!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila de un producto (virtualizada)
// ─────────────────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final ItemFactura item;
  final int index;

  const _ItemRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDiscount =
        item.descuentoPorcentaje != null && item.descuentoPorcentaje! > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cs.primary),
            ),
          ),
          const SizedBox(width: 10),

          // Nombre + detalle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productoNombre ?? item.productoId,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${item.cantidad.toInt()} × \$${_fmt.format(item.valor)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${item.descuentoPorcentaje!.toInt()}%',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Total línea
          Text(
            '\$${_fmt.format(item.subtotal)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: cs.primary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bloque de totales
// ─────────────────────────────────────────────────────────────────────────────

class _Totales extends StatelessWidget {
  final Factura factura;
  const _Totales({required this.factura});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _TotalRow(
              label: 'Subtotal',
              value: '\$${_fmt.format(factura.subtotal)}'),
          if (factura.descTotal > 0) ...[
            const SizedBox(height: 6),
            _TotalRow(
              label: 'Descuento',
              value: '-\$${_fmt.format(factura.descTotal)}',
              valueColor: AppTheme.success,
            ),
          ],
          if (factura.ivaTotal > 0) ...[
            const SizedBox(height: 6),
            _TotalRow(
                label: 'IVA (15%)',
                value: '\$${_fmt.format(factura.ivaTotal)}'),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '\$${_fmt.format(factura.total)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: cs.primary,
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
// Formas de pago
// ─────────────────────────────────────────────────────────────────────────────

class _FormasPago extends StatelessWidget {
  final List<FormaPago> formasPago;
  const _FormasPago({required this.formasPago});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.payment_outlined, label: 'Forma de pago'),
          const SizedBox(height: 8),
          ...formasPago.map(
            (fp) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: AppTheme.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fp.formaPagoNombre ?? 'Pago ${fp.formaPagoId}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '\$${_fmt.format(fp.valor)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers reutilizables
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;

  const _SectionTitle(
      {required this.icon, required this.label, this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: cs.primary),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TotalRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor),
        ),
      ],
    );
  }
}
