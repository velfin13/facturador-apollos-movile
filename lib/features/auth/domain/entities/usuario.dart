import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  vendedor,
  contador;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.vendedor:
        return 'Vendedor';
      case UserRole.contador:
        return 'Contador';
    }
  }
}

class Usuario extends Equatable {
  final String id;
  final String nombre;
  final String email;
  final UserRole rol;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.activo = true,
  });

  bool get esAdmin => rol == UserRole.admin;
  bool get esVendedor => rol == UserRole.vendedor;
  bool get esContador => rol == UserRole.contador;

  @override
  List<Object> get props => [id, nombre, email, rol, activo];
}
