// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producto_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductoModel _$ProductoModelFromJson(Map<String, dynamic> json) =>
    ProductoModel(
      idSysInProducto: json['idSysInProducto'] as String,
      idSysPeriodo: json['idSysPeriodo'] as String,
      descripcion: json['descripcion'] as String,
      idSysInMedida: json['idSysInMedida'] as String?,
      costo: (json['costo'] as num?)?.toDouble(),
      iva: json['iva'] as String?,
      precio1: (json['precio1'] as num?)?.toDouble(),
      precio2: (json['precio2'] as num?)?.toDouble(),
      precio3: (json['precio3'] as num?)?.toDouble(),
      barra: json['barra'] as String?,
      activo: json['activo'] as bool? ?? true,
      existencia: (json['existencia'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$ProductoModelToJson(ProductoModel instance) =>
    <String, dynamic>{
      'descripcion': instance.descripcion,
      'costo': instance.costo,
      'iva': instance.iva,
      'precio1': instance.precio1,
      'precio2': instance.precio2,
      'precio3': instance.precio3,
      'barra': instance.barra,
      'activo': instance.activo,
      'idSysInProducto': instance.idSysInProducto,
      'idSysPeriodo': instance.idSysPeriodo,
      'idSysInMedida': instance.idSysInMedida,
      'existencia': instance.existencia,
    };
