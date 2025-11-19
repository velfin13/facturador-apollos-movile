import 'package:equatable/equatable.dart';

class Producto extends Equatable {
  final String id; // idSysInProducto
  final String periodo; // idSysPeriodo
  final String descripcion; // descripcion (nombre del producto)
  final String? medida; // idSysInMedida
  final double? costo;
  final String? iva; // 'S' o 'N'
  final double? precio1;
  final double? precio2;
  final double? precio3;
  final String? barra; // código de barras
  final bool activo;
  final int stock; // desde inventario

  const Producto({
    required this.id,
    required this.periodo,
    required this.descripcion,
    this.medida,
    this.costo,
    this.iva,
    this.precio1,
    this.precio2,
    this.precio3,
    this.barra,
    this.activo = true,
    this.stock = 0,
  });

  double get precio => precio1 ?? 0.0;

  double get margen {
    if (costo == null || costo == 0) return 0;
    return ((precio - costo!) / costo!) * 100;
  }

  bool get disponible => activo && stock > 0;

  bool get tieneIva => iva == 'S';

  @override
  List<Object?> get props => [
    id,
    periodo,
    descripcion,
    medida,
    costo,
    iva,
    precio1,
    precio2,
    precio3,
    barra,
    activo,
    stock,
  ];
}
