import '../../domain/entities/producto.dart';

class ProductoModel extends Producto {
  final String? idSysInProducto;
  final double existencia;

  ProductoModel({
    this.idSysInProducto,
    super.idSysPeriodo,
    required super.descripcion,
    super.iva = 'N',
    super.activo = 'S',
    super.idSysUsuario,
    super.tipo,
    super.idImpuesto,
    super.precio1,
    super.precio2,
    super.precio3,
    super.barra,
    super.fraccion,
    super.idEstadoItem,
    this.existencia = 0,
  }) : super(
         id: idSysInProducto ?? '',
         stock: existencia.toInt(),
       );

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      idSysInProducto: json['idSysInProducto']?.toString(),
      idSysPeriodo: json['idSysPeriodo'] as int?,
      descripcion: json['descripcion'] as String? ?? '',
      iva: json['iva'] as String? ?? 'N',
      activo: json['activo'] as String? ?? 'S',
      idSysUsuario: json['idSysUsuario'] as int?,
      tipo: json['tipo'] as String?,
      idImpuesto: json['idImpuesto'] as int?,
      precio1: (json['precio1'] as num?)?.toDouble(),
      precio2: (json['precio2'] as num?)?.toDouble(),
      precio3: (json['precio3'] as num?)?.toDouble(),
      barra: json['barra'] as String?,
      fraccion: json['fraccion'] as int?,
      idEstadoItem: json['idEstadoItem'] as int?,
      existencia: (json['existencia'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'descripcion': descripcion,
      'iva': iva,
      'activo': activo,
      'precio1': precio1,
    };

    if (idSysPeriodo != null) json['idSysPeriodo'] = idSysPeriodo;
    if (idSysUsuario != null) json['idSysUsuario'] = idSysUsuario;
    if (tipo != null) json['tipo'] = tipo;
    if (idImpuesto != null) json['idImpuesto'] = idImpuesto;
    if (precio2 != null) json['precio2'] = precio2;
    if (precio3 != null) json['precio3'] = precio3;
    if (barra != null && barra!.isNotEmpty) json['barra'] = barra;
    if (fraccion != null) json['fraccion'] = fraccion;
    if (idEstadoItem != null) json['idEstadoItem'] = idEstadoItem;

    return json;
  }

  factory ProductoModel.fromEntity(Producto producto) {
    return ProductoModel(
      idSysInProducto: producto.id.isNotEmpty ? producto.id : null,
      idSysPeriodo: producto.idSysPeriodo,
      descripcion: producto.descripcion,
      iva: producto.iva,
      activo: producto.activo,
      idSysUsuario: producto.idSysUsuario,
      tipo: producto.tipo,
      idImpuesto: producto.idImpuesto,
      precio1: producto.precio1,
      precio2: producto.precio2,
      precio3: producto.precio3,
      barra: producto.barra,
      fraccion: producto.fraccion,
      idEstadoItem: producto.idEstadoItem,
      existencia: producto.stock.toDouble(),
    );
  }
}
