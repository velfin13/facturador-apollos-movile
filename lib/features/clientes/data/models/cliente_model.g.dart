// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClienteModel _$ClienteModelFromJson(Map<String, dynamic> json) => ClienteModel(
  idSysFcCliente: json['idSysFcCliente'] as String,
  idSysPeriodo: json['idSysPeriodo'] as String,
  nombre: json['nombre'] as String,
  direccion: json['direccion'] as String?,
  telefono: json['telefono'] as String?,
  ruc: json['ruc'] as String,
  activo: json['activo'] as bool? ?? true,
  ciudad: json['ciudad'] as String?,
  email: json['email'] as String?,
  tipo: json['tipo'] as String?,
);

Map<String, dynamic> _$ClienteModelToJson(ClienteModel instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'direccion': instance.direccion,
      'telefono': instance.telefono,
      'ruc': instance.ruc,
      'activo': instance.activo,
      'ciudad': instance.ciudad,
      'email': instance.email,
      'tipo': instance.tipo,
      'idSysFcCliente': instance.idSysFcCliente,
      'idSysPeriodo': instance.idSysPeriodo,
    };
