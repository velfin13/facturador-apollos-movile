import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/usuario.dart';

part 'usuario_model.g.dart';

@JsonSerializable()
class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.nombre,
    required super.email,
    required super.rol,
    super.activo,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) =>
      _$UsuarioModelFromJson(json);

  Map<String, dynamic> toJson() => _$UsuarioModelToJson(this);

  factory UsuarioModel.fromEntity(Usuario usuario) {
    return UsuarioModel(
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: usuario.rol,
      activo: usuario.activo,
    );
  }
}
