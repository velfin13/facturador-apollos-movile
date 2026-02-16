import 'dart:developer' as dev;

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/auth/jwt_utils.dart';
import '../../../../core/auth/keycloak_config.dart';
import '../../../../core/auth/token_storage.dart';
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
  final FlutterAppAuth _appAuth;

  AuthRemoteDataSourceImpl(this._appAuth);

  @override
  Future<AuthSession> login(String email, String password) async {
    // password no se usa en el flujo OIDC, se mantiene por compatibilidad de interfaz
    final _ = password;
    dev.log(
      'AuthRemoteDataSource.login: iniciando authorizeAndExchangeCode',
      name: 'auth',
    );
    dev.log(
      'AuthRemoteDataSource.login: issuer=${KeycloakConfig.issuer}',
      name: 'auth',
    );
    dev.log(
      'AuthRemoteDataSource.login: redirectUri=${KeycloakConfig.redirectUri}',
      name: 'auth',
    );
    dev.log(
      'AuthRemoteDataSource.login: clientId=${KeycloakConfig.clientId}',
      name: 'auth',
    );

    AuthorizationTokenResponse? result;
    try {
      dev.log(
        'AuthRemoteDataSource.login: ANTES de authorizeAndExchangeCode',
        name: 'auth',
      );
      result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          KeycloakConfig.clientId,
          KeycloakConfig.redirectUri,
          issuer: KeycloakConfig.issuer,
          scopes: KeycloakConfig.scopes,
          loginHint: email.isNotEmpty ? email : null,
          promptValues: const ['login'],
          allowInsecureConnections: false,
          preferEphemeralSession: false,
        ),
      );
      dev.log(
        'AuthRemoteDataSource.login: DESPUES de authorizeAndExchangeCode, result=$result',
        name: 'auth',
      );
    } on Exception catch (e, stackTrace) {
      dev.log('AuthRemoteDataSource.login: ERROR COMPLETO: $e', name: 'auth');
      dev.log(
        'AuthRemoteDataSource.login: stackTrace: $stackTrace',
        name: 'auth',
      );

      final errorStr = e.toString();

      // Usuario canceló explícitamente
      if (errorStr.contains('user_cancelled') ||
          errorStr.contains('CANCELED') ||
          errorStr.contains('User cancelled')) {
        throw Exception('Login cancelado por el usuario');
      }

      // Error de estado no almacenado
      if (errorStr.toLowerCase().contains('no stored state') ||
          errorStr.toLowerCase().contains('state mismatch')) {
        throw Exception(
          'Error de autenticación: No se pudo completar el flujo OAuth. '
          'Por favor, intente nuevamente.',
        );
      }

      // Mostrar el error real para depuración
      throw Exception('Error de autenticación: $errorStr');
    }

    if (result == null) {
      throw Exception('No se recibió respuesta del servidor de autenticación');
    }

    dev.log(
      'AuthRemoteDataSource.login: recibido accessToken=${result.accessToken != null}, refreshToken=${result.refreshToken != null}, idToken=${result.idToken != null}',
      name: 'auth',
    );

    final accessToken = result.accessToken;
    if (accessToken == null) {
      throw Exception('No se recibió access_token');
    }

    final claims = decodeJwt(accessToken);
    final usuario = _usuarioFromClaims(claims);

    return AuthSession(
      usuario: usuario,
      accessToken: accessToken,
      refreshToken: result.refreshToken,
      idToken: result.idToken,
      accessTokenExpiry: result.accessTokenExpirationDateTime,
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    dev.log(
      'AuthRemoteDataSource.refresh: solicitando nuevo token',
      name: 'auth',
    );
    final result = await _appAuth.token(
      TokenRequest(
        KeycloakConfig.clientId,
        KeycloakConfig.redirectUri,
        issuer: KeycloakConfig.issuer,
        refreshToken: refreshToken,
        scopes: KeycloakConfig.scopes,
      ),
    );

    dev.log(
      'AuthRemoteDataSource.refresh: recibido accessToken=${result.accessToken != null}, refreshToken=${result.refreshToken != null}, idToken=${result.idToken != null}',
      name: 'auth',
    );

    final accessToken = result.accessToken;
    if (accessToken == null) {
      throw Exception('No se recibió access_token en refresh');
    }

    final claims = decodeJwt(accessToken);
    final usuario = _usuarioFromClaims(claims);

    return AuthSession(
      usuario: usuario,
      accessToken: accessToken,
      refreshToken: result.refreshToken ?? refreshToken,
      idToken: result.idToken,
      accessTokenExpiry: result.accessTokenExpirationDateTime,
    );
  }

  @override
  Future<void> logout({String? idTokenHint}) async {
    try {
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idTokenHint,
          postLogoutRedirectUrl: KeycloakConfig.postLogoutRedirectUri,
          issuer: KeycloakConfig.issuer,
        ),
      );
    } catch (_) {
      dev.log(
        'AuthRemoteDataSource.logout: error cerrando sesión remota',
        name: 'auth',
      );
      // Ignoramos errores silenciosamente; el logout local seguirá.
    }
  }

  UsuarioModel _usuarioFromClaims(Map<String, dynamic> claims) {
    dev.log('Claims completos: $claims', name: 'auth');

    final id = claims['sub']?.toString() ?? 'desconocido';
    final nombre = (claims['name'] ?? claims['preferred_username'] ?? 'usuario')
        .toString();
    final email = (claims['email'] ?? '').toString();
    final rolesStrings = _extractRoles(claims);
    dev.log('Roles extraidos: $rolesStrings', name: 'auth');
    final roles = _mapRoles(rolesStrings);
    dev.log('Roles mapeados: $roles', name: 'auth');

    // Si solo tiene un rol, asignarlo automaticamente como activo
    // Si no tiene roles, rolActivo queda null
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

      // 1) Prioriza roles del cliente autorizado (azp) si existe.
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

      // 2) Agrega roles de todos los clientes presentes en resource_access.
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
          break;
        case 'CLIENTE':
          mappedRoles.add(UserRole.cliente);
          break;
      }
    }

    dev.log('Roles validos encontrados: $mappedRoles', name: 'auth');
    return mappedRoles;
  }
}
