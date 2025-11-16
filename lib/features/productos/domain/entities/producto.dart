import 'package:equatable/equatable.dart';

class Producto extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final double precio;
  final double? costo;
  final int stock;
  final String? categoria;
  final bool activo;
  final DateTime fechaCreacion;

  const Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.costo,
    this.stock = 0,
    this.categoria,
    this.activo = true,
    required this.fechaCreacion,
  });

  double get margen {
    if (costo == null || costo == 0) return 0;
    return ((precio - costo!) / costo!) * 100;
  }

  bool get disponible => activo && stock > 0;

  @override
  List<Object?> get props => [
    id,
    codigo,
    nombre,
    descripcion,
    precio,
    costo,
    stock,
    categoria,
    activo,
    fechaCreacion,
  ];
}
