// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioModel _$UsuarioModelFromJson(Map<String, dynamic> json) => UsuarioModel(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  email: json['email'] as String,
  rol: $enumDecode(_$UserRoleEnumMap, json['rol']),
  activo: json['activo'] as bool? ?? true,
);

Map<String, dynamic> _$UsuarioModelToJson(UsuarioModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'email': instance.email,
      'rol': _$UserRoleEnumMap[instance.rol]!,
      'activo': instance.activo,
    };

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.vendedor: 'vendedor',
  UserRole.contador: 'contador',
};
