import 'package:equatable/equatable.dart';

class Factura extends Equatable {
  final String id; // idSysFcCabVenta
  final String periodo; // idSysPeriodo
  final String? tipo;
  final DateTime fecha;
  final String clienteId; // idSysFcCliente
  final String? clienteNombre; // desde cliente
  final String? numFact;
  final String? observacion;
  final double total; // calculado desde detalles
  final List<ItemFactura> items;
  final List<FormaPago> formasPago;

  const Factura({
    required this.id,
    required this.periodo,
    this.tipo,
    required this.fecha,
    required this.clienteId,
    this.clienteNombre,
    this.numFact,
    this.observacion,
    required this.total,
    required this.items,
    required this.formasPago,
  });

  @override
  List<Object?> get props => [
    id,
    periodo,
    tipo,
    fecha,
    clienteId,
    clienteNombre,
    numFact,
    observacion,
    total,
    items,
    formasPago,
  ];
}

class ItemFactura extends Equatable {
  final String productoId; // idSysInProducto
  final String? productoNombre; // desde producto
  final double cantidad;
  final double valor; // precio unitario
  final double? descuentoPorcentaje;
  final String? bodegaId; // idSysInBodega

  const ItemFactura({
    required this.productoId,
    this.productoNombre,
    required this.cantidad,
    required this.valor,
    this.descuentoPorcentaje,
    this.bodegaId,
  });

  double get subtotal {
    final base = cantidad * valor;
    if (descuentoPorcentaje != null) {
      return base * (1 - (descuentoPorcentaje! / 100));
    }
    return base;
  }

  @override
  List<Object?> get props => [
    productoId,
    productoNombre,
    cantidad,
    valor,
    descuentoPorcentaje,
    bodegaId,
  ];
}

class FormaPago extends Equatable {
  final String formaPagoId; // idSysFcFormaPago
  final String? formaPagoNombre; // desde forma de pago
  final double valor;
  final String? numero; // número de cheque, transferencia, etc
  final String? referencia;
  final DateTime? fechaVence;

  const FormaPago({
    required this.formaPagoId,
    this.formaPagoNombre,
    required this.valor,
    this.numero,
    this.referencia,
    this.fechaVence,
  });

  @override
  List<Object?> get props => [
    formaPagoId,
    formaPagoNombre,
    valor,
    numero,
    referencia,
    fechaVence,
  ];
}
