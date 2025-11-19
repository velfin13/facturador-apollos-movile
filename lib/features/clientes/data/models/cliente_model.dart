import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/cliente.dart';

part 'cliente_model.g.dart';

@JsonSerializable()
class ClienteModel extends Cliente {
  @JsonKey(name: 'idSysFcCliente')
  final String idSysFcCliente;

  @JsonKey(name: 'idSysPeriodo')
  final String idSysPeriodo;

  const ClienteModel({
    required this.idSysFcCliente,
    required this.idSysPeriodo,
    required super.nombre,
    super.direccion,
    super.telefono,
    required super.ruc,
    super.activo = true,
    super.ciudad,
    super.email,
    super.tipo,
  }) : super(id: idSysFcCliente, periodo: idSysPeriodo);

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    // Convertir activo de "S"/"N" a bool
    final activo = json['activo'] == 'S';

    return ClienteModel(
      idSysFcCliente: json['idSysFcCliente'] as String,
      idSysPeriodo: json['idSysPeriodo'] as String,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      ruc: json['ruc'] as String,
      activo: activo,
      ciudad: json['ciudad'] as String?,
      email: json['eMail'] as String?,
      tipo: json['tipo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$ClienteModelToJson(this);

  factory ClienteModel.fromEntity(Cliente cliente) {
    return ClienteModel(
      idSysFcCliente: cliente.id,
      idSysPeriodo: cliente.periodo,
      nombre: cliente.nombre,
      direccion: cliente.direccion,
      telefono: cliente.telefono,
      ruc: cliente.ruc,
      activo: cliente.activo,
      ciudad: cliente.ciudad,
      email: cliente.email,
      tipo: cliente.tipo,
    );
  }
}
