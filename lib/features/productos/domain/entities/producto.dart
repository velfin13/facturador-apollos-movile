import 'package:equatable/equatable.dart';

class Producto extends Equatable {
  final String id; // idSysInProducto
  final int? idSysPeriodo;
  final String descripcion;
  final String iva; // 'S' o 'N'
  final String activo; // 'S' o 'N'
  final int? idSysUsuario;
  final String? tipo; // 'B' = Bien, 'S' = Servicio
  final int? idImpuesto;
  final double? precio1;
  final double? precio2;
  final double? precio3;
  final String? barra;
  final int? fraccion;
  final int? idEstadoItem;
  final int stock;

  const Producto({
    required this.id,
    this.idSysPeriodo,
    required this.descripcion,
    this.iva = 'N',
    this.activo = 'S',
    this.idSysUsuario,
    this.tipo,
    this.idImpuesto,
    this.precio1,
    this.precio2,
    this.precio3,
    this.barra,
    this.fraccion,
    this.idEstadoItem,
    this.stock = 0,
  });

  double get precio => precio1 ?? 0.0;

  bool get estaActivo => activo == 'S';

  bool get tieneIva => iva == 'S';

  bool get esBien => tipo == 'B';

  bool get esServicio => tipo == 'S';

  String get tipoDescripcion {
    switch (tipo) {
      case 'B':
        return 'Bien';
      case 'S':
        return 'Servicio';
      default:
        return 'No definido';
    }
  }

  @override
  List<Object?> get props => [
    id,
    idSysPeriodo,
    descripcion,
    iva,
    activo,
    idSysUsuario,
    tipo,
    idImpuesto,
    precio1,
    precio2,
    precio3,
    barra,
    fraccion,
    idEstadoItem,
    stock,
  ];
}
