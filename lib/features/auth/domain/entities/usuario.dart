import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.vendedor:
        return Icons.point_of_sale;
      case UserRole.contador:
        return Icons.calculate;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.vendedor:
        return Colors.blue;
      case UserRole.contador:
        return Colors.teal;
    }
  }
}

class Usuario extends Equatable {
  final String id;
  final String nombre;
  final String email;
  final Set<UserRole> roles;
  final UserRole? rolActivo;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.roles,
    this.rolActivo,
    this.activo = true,
  });

  // Helpers para verificar si TIENE el rol (en cualquiera de sus roles)
  bool get tieneRolAdmin => roles.contains(UserRole.admin);
  bool get tieneRolVendedor => roles.contains(UserRole.vendedor);
  bool get tieneRolContador => roles.contains(UserRole.contador);

  // Helpers para verificar el rol ACTIVO
  bool get esAdmin => rolActivo == UserRole.admin;
  bool get esVendedor => rolActivo == UserRole.vendedor;
  bool get esContador => rolActivo == UserRole.contador;

  // Indica si el usuario tiene multiples roles
  bool get tieneMultiplesRoles => roles.length > 1;

  // Indica si ya selecciono un rol activo
  bool get tieneRolSeleccionado => rolActivo != null;

  // Lista ordenada de roles para mostrar en UI
  List<UserRole> get rolesOrdenados =>
      roles.toList()..sort((a, b) => a.index.compareTo(b.index));

  // Crear copia con rol activo diferente
  Usuario conRolActivo(UserRole rol) {
    assert(
        roles.contains(rol), 'El rol debe estar en la lista de roles del usuario');
    return Usuario(
      id: id,
      nombre: nombre,
      email: email,
      roles: roles,
      rolActivo: rol,
      activo: activo,
    );
  }

  @override
  List<Object?> get props => [id, nombre, email, roles, rolActivo, activo];
}
