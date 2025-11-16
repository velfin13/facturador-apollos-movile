// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClienteModel _$ClienteModelFromJson(Map<String, dynamic> json) => ClienteModel(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  razonSocial: json['razonSocial'] as String?,
  identificacion: json['identificacion'] as String,
  email: json['email'] as String?,
  telefono: json['telefono'] as String?,
  direccion: json['direccion'] as String?,
  activo: json['activo'] as bool? ?? true,
  fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
);

Map<String, dynamic> _$ClienteModelToJson(ClienteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'razonSocial': instance.razonSocial,
      'identificacion': instance.identificacion,
      'email': instance.email,
      'telefono': instance.telefono,
      'direccion': instance.direccion,
      'activo': instance.activo,
      'fechaCreacion': instance.fechaCreacion.toIso8601String(),
    };
