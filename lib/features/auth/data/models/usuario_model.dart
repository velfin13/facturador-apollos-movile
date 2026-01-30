import '../../domain/entities/usuario.dart';

const _userRoleEnumMap = {
  UserRole.admin: 'Administrador',
  UserRole.vendedor: 'Vendedor',
  UserRole.contador: 'Contador',
};

class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.nombre,
    required super.email,
    required Set<UserRole> roles,
    UserRole? rolActivo,
    super.activo,
  }) : super(roles: roles, rolActivo: rolActivo);

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    Set<UserRole> roles;
    UserRole? rolActivo;

    // Compatibilidad con formato antiguo (un solo rol)
    if (json.containsKey('rol') && !json.containsKey('roles')) {
      final rolStr = json['rol'] as String;
      final rol = _userRoleEnumMap.entries
          .firstWhere(
            (e) => e.value == rolStr,
            orElse: () => const MapEntry(UserRole.vendedor, 'vendedor'),
          )
          .key;
      roles = {rol};
      rolActivo = rol;
    } else {
      // Formato nuevo (multiples roles)
      final rolesJson = json['roles'] as List<dynamic>?;
      roles = rolesJson != null
          ? rolesJson
              .map((r) => _userRoleEnumMap.entries
                  .firstWhere(
                    (e) => e.value == r,
                    orElse: () => const MapEntry(UserRole.vendedor, 'vendedor'),
                  )
                  .key)
              .toSet()
          : {UserRole.vendedor};

      // Parsear rol activo
      final rolActivoStr = json['rolActivo'] as String?;
      if (rolActivoStr != null) {
        rolActivo = _userRoleEnumMap.entries
            .firstWhere(
              (e) => e.value == rolActivoStr,
              orElse: () => const MapEntry(UserRole.vendedor, 'vendedor'),
            )
            .key;
      }
    }

    return UsuarioModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      roles: roles,
      rolActivo: rolActivo,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'roles': roles.map((r) => _userRoleEnumMap[r]).toList(),
        'rolActivo': rolActivo != null ? _userRoleEnumMap[rolActivo] : null,
        'activo': activo,
      };

  factory UsuarioModel.fromEntity(Usuario usuario) {
    return UsuarioModel(
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      roles: usuario.roles,
      rolActivo: usuario.rolActivo,
      activo: usuario.activo,
    );
  }

  @override
  UsuarioModel conRolActivo(UserRole rol) {
    return UsuarioModel(
      id: id,
      nombre: nombre,
      email: email,
      roles: roles,
      rolActivo: rol,
      activo: activo,
    );
  }
}
