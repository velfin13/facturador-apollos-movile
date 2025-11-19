import 'package:equatable/equatable.dart';

class Cliente extends Equatable {
  final String id; // idSysFcCliente
  final String periodo; // idSysPeriodo
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String ruc; // identificación
  final bool activo;
  final String? ciudad;
  final String? email;
  final String? tipo; // tipo de cliente

  const Cliente({
    required this.id,
    required this.periodo,
    required this.nombre,
    this.direccion,
    this.telefono,
    required this.ruc,
    this.activo = true,
    this.ciudad,
    this.email,
    this.tipo,
  });

  @override
  List<Object?> get props => [
    id,
    periodo,
    nombre,
    direccion,
    telefono,
    ruc,
    activo,
    ciudad,
    email,
    tipo,
  ];
}
