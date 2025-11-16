import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/cliente.dart';

part 'cliente_model.g.dart';

@JsonSerializable()
class ClienteModel extends Cliente {
  const ClienteModel({
    required super.id,
    required super.nombre,
    super.razonSocial,
    required super.identificacion,
    super.email,
    super.telefono,
    super.direccion,
    super.activo,
    required super.fechaCreacion,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) =>
      _$ClienteModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClienteModelToJson(this);

  factory ClienteModel.fromEntity(Cliente cliente) {
    return ClienteModel(
      id: cliente.id,
      nombre: cliente.nombre,
      razonSocial: cliente.razonSocial,
      identificacion: cliente.identificacion,
      email: cliente.email,
      telefono: cliente.telefono,
      direccion: cliente.direccion,
      activo: cliente.activo,
      fechaCreacion: cliente.fechaCreacion,
    );
  }
}
