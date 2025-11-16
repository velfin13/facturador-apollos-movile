import 'package:equatable/equatable.dart';

class Cliente extends Equatable {
  final String id;
  final String nombre;
  final String? razonSocial;
  final String identificacion; // RUC, CI, etc.
  final String? email;
  final String? telefono;
  final String? direccion;
  final bool activo;
  final DateTime fechaCreacion;

  const Cliente({
    required this.id,
    required this.nombre,
    this.razonSocial,
    required this.identificacion,
    this.email,
    this.telefono,
    this.direccion,
    this.activo = true,
    required this.fechaCreacion,
  });

  @override
  List<Object?> get props => [
    id,
    nombre,
    razonSocial,
    identificacion,
    email,
    telefono,
    direccion,
    activo,
    fechaCreacion,
  ];
}
