import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/producto.dart';

part 'producto_model.g.dart';

@JsonSerializable()
class ProductoModel extends Producto {
  const ProductoModel({
    required super.id,
    required super.codigo,
    required super.nombre,
    super.descripcion,
    required super.precio,
    super.costo,
    super.stock,
    super.categoria,
    super.activo,
    required super.fechaCreacion,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) =>
      _$ProductoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductoModelToJson(this);

  factory ProductoModel.fromEntity(Producto producto) {
    return ProductoModel(
      id: producto.id,
      codigo: producto.codigo,
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      precio: producto.precio,
      costo: producto.costo,
      stock: producto.stock,
      categoria: producto.categoria,
      activo: producto.activo,
      fechaCreacion: producto.fechaCreacion,
    );
  }
}
