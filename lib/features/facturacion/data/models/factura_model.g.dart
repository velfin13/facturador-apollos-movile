// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'factura_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FacturaModel _$FacturaModelFromJson(Map<String, dynamic> json) => FacturaModel(
  id: json['id'] as String,
  clienteNombre: json['clienteNombre'] as String,
  total: (json['total'] as num).toDouble(),
  fecha: DateTime.parse(json['fecha'] as String),
  itemsModel: (json['items'] as List<dynamic>)
      .map((e) => ItemFacturaModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FacturaModelToJson(FacturaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clienteNombre': instance.clienteNombre,
      'total': instance.total,
      'fecha': instance.fecha.toIso8601String(),
      'items': instance.itemsModel.map((e) => e.toJson()).toList(),
    };

ItemFacturaModel _$ItemFacturaModelFromJson(Map<String, dynamic> json) =>
    ItemFacturaModel(
      descripcion: json['descripcion'] as String,
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
    );

Map<String, dynamic> _$ItemFacturaModelToJson(ItemFacturaModel instance) =>
    <String, dynamic>{
      'descripcion': instance.descripcion,
      'cantidad': instance.cantidad,
      'precioUnitario': instance.precioUnitario,
    };
