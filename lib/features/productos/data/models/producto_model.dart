import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/producto.dart';

part 'producto_model.g.dart';

@JsonSerializable()
class ProductoModel extends Producto {
  @JsonKey(name: 'idSysInProducto')
  final String idSysInProducto;

  @JsonKey(name: 'idSysPeriodo')
  final String idSysPeriodo;

  @JsonKey(name: 'idSysInMedida')
  final String? idSysInMedida;

  @JsonKey(name: 'existencia')
  final double existencia;

  ProductoModel({
    required this.idSysInProducto,
    required this.idSysPeriodo,
    required super.descripcion,
    this.idSysInMedida,
    super.costo,
    super.iva,
    super.precio1,
    super.precio2,
    super.precio3,
    super.barra,
    super.activo = true,
    this.existencia = 0,
  }) : super(
         id: idSysInProducto,
         periodo: idSysPeriodo,
         medida: idSysInMedida,
         stock: existencia.toInt(),
       );

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    // Convertir activo de "S"/"N" a bool
    final activo = json['activo'] == 'S';
    // IVA mantenerlo como String "S" o "N"
    final ivaValue = json['iva'] as String? ?? 'N';

    return ProductoModel(
      idSysInProducto: json['idSysInProducto'] as String,
      idSysPeriodo: json['idSysPeriodo'] as String,
      descripcion: json['descripcion'] as String,
      idSysInMedida: json['idSysInMedida'] as String?,
      costo: (json['costo'] as num?)?.toDouble() ?? 0.0,
      iva: ivaValue,
      precio1: (json['precio1'] as num?)?.toDouble() ?? 0.0,
      precio2: (json['precio2'] as num?)?.toDouble() ?? 0.0,
      precio3: (json['precio3'] as num?)?.toDouble() ?? 0.0,
      barra: json['barra'] as String? ?? '',
      activo: activo,
      existencia: (json['existencia'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => _$ProductoModelToJson(this);

  factory ProductoModel.fromEntity(Producto producto) {
    return ProductoModel(
      idSysInProducto: producto.id,
      idSysPeriodo: producto.periodo,
      descripcion: producto.descripcion,
      idSysInMedida: producto.medida,
      costo: producto.costo,
      iva: producto.iva,
      precio1: producto.precio1,
      precio2: producto.precio2,
      precio3: producto.precio3,
      barra: producto.barra,
      activo: producto.activo,
      existencia: producto.stock.toDouble(),
    );
  }
}
