// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producto_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductoModel _$ProductoModelFromJson(Map<String, dynamic> json) =>
    ProductoModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      costo: (json['costo'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      categoria: json['categoria'] as String?,
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
    );

Map<String, dynamic> _$ProductoModelToJson(ProductoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'codigo': instance.codigo,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'precio': instance.precio,
      'costo': instance.costo,
      'stock': instance.stock,
      'categoria': instance.categoria,
      'activo': instance.activo,
      'fechaCreacion': instance.fechaCreacion.toIso8601String(),
    };
