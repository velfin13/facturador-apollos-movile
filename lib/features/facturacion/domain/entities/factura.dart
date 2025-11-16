import 'package:equatable/equatable.dart';

class Factura extends Equatable {
  final String id;
  final String clienteNombre;
  final double total;
  final DateTime fecha;
  final List<ItemFactura> items;

  const Factura({
    required this.id,
    required this.clienteNombre,
    required this.total,
    required this.fecha,
    required this.items,
  });

  @override
  List<Object> get props => [id, clienteNombre, total, fecha, items];
}

class ItemFactura extends Equatable {
  final String descripcion;
  final int cantidad;
  final double precioUnitario;

  const ItemFactura({
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  @override
  List<Object> get props => [descripcion, cantidad, precioUnitario];
}
