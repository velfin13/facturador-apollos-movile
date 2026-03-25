import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/auth/jwt_utils.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_config.dart';
import '../../domain/entities/usuario.dart';
import '../models/auth_session.dart';
import '../models/usuario_model.dart';

abstract class AuthLocalDataSource {
  Future<AuthSession?> getSession();
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final TokenStorage _storage;

  AuthLocalDataSourceImpl(this._storage);

  @override
  Future<AuthSession?> getSession() async {
    final accessToken = await _storage.accessToken;
    if (accessToken == null) return null;

    final userJson = await _storage.readUserJson();
    if (userJson == null) return null;

    final refreshToken = await _storage.refreshToken;
    final idToken = await _storage.idToken;
    final expires = await _storage.accessExpiry;
    var usuario = UsuarioModel.fromJson(userJson);

    // Recuperar rol seleccionado si existe
    final selectedRoleStr = await _storage.selectedRole;
    if (selectedRoleStr != null && usuario.rolActivo == null) {
      final selectedRole = UserRole.values.firstWhere(
        (r) => r.name == selectedRoleStr,
        orElse: () => usuario.roles.first,
      );
      if (usuario.roles.contains(selectedRole)) {
        usuario = usuario.conRolActivo(selectedRole);
      }
    }

    return AuthSession(
      usuario: usuario,
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      accessTokenExpiry: expires,
    );
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      idToken: session.idToken,
      accessExpiry: session.accessTokenExpiry,
    );
    await _storage.saveUserJson(session.usuario.toJson());
  }

  @override
  Future<void> clearSession() => _storage.clear();
}

abstract class AuthRemoteDataSource {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> refresh(String refreshToken);
  Future<void> logout({String? idTokenHint});
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: ApiConfig.headers,
  ));

  AuthRemoteDataSourceImpl();

  @override
  Future<AuthSession> login(String username, String password) async {
    dev.log('AuthRemoteDataSource.login: POST /Auth/login con username=$username', name: 'auth');

    if (username.isEmpty || password.isEmpty) {
      throw Exception('Usuario y contraseña son obligatorios');
    }

    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final body = response.data;
      if (body is! Map || body['status'] != true || body['data'] == null) {
        final msg = body is Map ? body['message']?.toString() : null;
        throw Exception(msg ?? 'Credenciales incorrectas');
      }

      final data = body['data'] as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'] as int? ?? 300;

      if (accessToken == null) {
        throw Exception('No se recibió access_token');
      }

      dev.log('AuthRemoteDataSource.login: token recibido, expires_in=$expiresIn', name: 'auth');

      final claims = decodeJwt(accessToken);
      final usuario = _usuarioFromClaims(claims);

      return AuthSession(
        usuario: usuario,
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: null,
        accessTokenExpiry: DateTime.now().add(Duration(seconds: expiresIn)),
      );
    } on DioException catch (e) {
      dev.log('AuthRemoteDataSource.login: DioError ${e.response?.statusCode}', name: 'auth');
      final body = e.response?.data;
      final msg = body is Map ? body['message']?.toString() : null;

      if (e.response?.statusCode == 401) {
        throw Exception(msg ?? 'Usuario o contraseña incorrectos');
      }
      throw Exception(msg ?? 'Error de conexión al servidor');
    }
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    dev.log('AuthRemoteDataSource.refresh: POST /Auth/refresh', name: 'auth');

    try {
      final response = await _dio.post(
        '/Auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      if (body is! Map || body['status'] != true || body['data'] == null) {
        throw Exception('No se pudo renovar la sesión');
      }

      final data = body['data'] as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'] as int? ?? 300;

      if (accessToken == null) {
        throw Exception('No se recibió access_token en refresh');
      }

      final claims = decodeJwt(accessToken);
      final usuario = _usuarioFromClaims(claims);

      return AuthSession(
        usuario: usuario,
        accessToken: accessToken,
        refreshToken: newRefreshToken ?? refreshToken,
        idToken: null,
        accessTokenExpiry: DateTime.now().add(Duration(seconds: expiresIn)),
      );
    } on DioException catch (e) {
      dev.log('AuthRemoteDataSource.refresh: error ${e.response?.statusCode}', name: 'auth');
      throw Exception('Sesión expirada. Inicia sesión nuevamente.');
    }
  }

  @override
  Future<void> logout({String? idTokenHint}) async {
    // No hay endpoint de logout en la API, solo limpiamos localmente
    dev.log('AuthRemoteDataSource.logout: limpieza local', name: 'auth');
  }

  UsuarioModel _usuarioFromClaims(Map<String, dynamic> claims) {
    dev.log('Claims: $claims', name: 'auth');

    final id = claims['sub']?.toString() ?? 'desconocido';
    final nombre = (claims['name'] ?? claims['preferred_username'] ?? 'usuario').toString();
    final email = (claims['email'] ?? '').toString();
    final rolesStrings = _extractRoles(claims);
    final roles = _mapRoles(rolesStrings);

    final rolActivo = roles.length == 1 ? roles.first : null;

    return UsuarioModel(
      id: id,
      nombre: nombre,
      email: email.isNotEmpty ? email : nombre,
      roles: roles,
      rolActivo: rolActivo,
      activo: true,
    );
  }

  List<String> _extractRoles(Map<String, dynamic> claims) {
    final roles = <String>{};

    final realm = claims['realm_access'];
    if (realm is Map && realm['roles'] is List) {
      roles.addAll(
        (realm['roles'] as List)
            .whereType<Object>()
            .map((r) => r.toString())
            .where((r) => r.isNotEmpty),
      );
    }

    final resource = claims['resource_access'];
    if (resource is Map && resource.isNotEmpty) {
      final preferredClientId = claims['azp']?.toString();
      if (preferredClientId != null && preferredClientId.isNotEmpty) {
        final preferred = resource[preferredClientId];
        if (preferred is Map && preferred['roles'] is List) {
          roles.addAll(
            (preferred['roles'] as List)
                .whereType<Object>()
                .map((r) => r.toString())
                .where((r) => r.isNotEmpty),
          );
        }
      }
      for (final value in resource.values) {
        if (value is Map && value['roles'] is List) {
          roles.addAll(
            (value['roles'] as List)
                .whereType<Object>()
                .map((r) => r.toString())
                .where((r) => r.isNotEmpty),
          );
        }
      }
    }

    return roles.toList();
  }

  Set<UserRole> _mapRoles(List<String> roles) {
    final mappedRoles = <UserRole>{};
    for (final role in roles) {
      switch (role.trim().toUpperCase()) {
        case 'ADMIN':
        case 'ADMINISTRADOR':
          mappedRoles.add(UserRole.admin);
        case 'CLIENTE':
          mappedRoles.add(UserRole.cliente);
      }
    }
    return mappedRoles;
  }
}
