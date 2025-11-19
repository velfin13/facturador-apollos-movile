// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'factura_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FacturaModel _$FacturaModelFromJson(Map<String, dynamic> json) => FacturaModel(
  idSysFcCabVenta: json['idSysFcCabVenta'] as String,
  idSysPeriodo: json['idSysPeriodo'] as String,
  tipo: json['tipo'] as String?,
  fecha: DateTime.parse(json['fecha'] as String),
  idSysFcCliente: json['idSysFcCliente'] as String,
  clienteNombre: json['clienteNombre'] as String?,
  numFact: json['numFact'] as String?,
  observacion: json['observacion'] as String?,
  total: (json['total'] as num).toDouble(),
  detalles: (json['detalles'] as List<dynamic>)
      .map((e) => ItemFacturaModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  formasPagoModel: (json['formasPago'] as List<dynamic>)
      .map((e) => FormaPagoModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FacturaModelToJson(FacturaModel instance) =>
    <String, dynamic>{
      'tipo': ?instance.tipo,
      'fecha': instance.fecha.toIso8601String(),
      'clienteNombre': ?instance.clienteNombre,
      'numFact': ?instance.numFact,
      'observacion': ?instance.observacion,
      'total': instance.total,
      'idSysFcCabVenta': instance.idSysFcCabVenta,
      'idSysPeriodo': instance.idSysPeriodo,
      'idSysFcCliente': instance.idSysFcCliente,
      'detalles': instance.detalles.map((e) => e.toJson()).toList(),
      'formasPago': instance.formasPagoModel.map((e) => e.toJson()).toList(),
    };

ItemFacturaModel _$ItemFacturaModelFromJson(Map<String, dynamic> json) =>
    ItemFacturaModel(
      idSysInProducto: json['idSysInProducto'] as String,
      productoNombre: json['productoNombre'] as String?,
      cantidad: (json['cantidad'] as num).toDouble(),
      valor: (json['valor'] as num).toDouble(),
      descuentoPorcentaje: (json['descuentoPorcentaje'] as num?)?.toDouble(),
      bodegaId: json['bodegaId'] as String?,
    );

Map<String, dynamic> _$ItemFacturaModelToJson(ItemFacturaModel instance) =>
    <String, dynamic>{
      'productoNombre': ?instance.productoNombre,
      'cantidad': instance.cantidad,
      'valor': instance.valor,
      'descuentoPorcentaje': ?instance.descuentoPorcentaje,
      'bodegaId': ?instance.bodegaId,
      'idSysInProducto': instance.idSysInProducto,
    };

FormaPagoModel _$FormaPagoModelFromJson(Map<String, dynamic> json) =>
    FormaPagoModel(
      idSysFcFormaPago: json['idSysFcFormaPago'] as String,
      formaPagoNombre: json['formaPagoNombre'] as String?,
      valor: (json['valor'] as num).toDouble(),
      numero: json['numero'] as String?,
      referencia: json['referencia'] as String?,
      fechaVence: json['fechaVence'] == null
          ? null
          : DateTime.parse(json['fechaVence'] as String),
    );

Map<String, dynamic> _$FormaPagoModelToJson(FormaPagoModel instance) =>
    <String, dynamic>{
      'formaPagoNombre': ?instance.formaPagoNombre,
      'valor': instance.valor,
      'numero': ?instance.numero,
      'referencia': ?instance.referencia,
      'fechaVence': ?instance.fechaVence?.toIso8601String(),
      'idSysFcFormaPago': instance.idSysFcFormaPago,
    };
