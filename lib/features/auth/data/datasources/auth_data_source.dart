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
    final usuario = UsuarioModel.fromJson(userJson);

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
    dev.log('AuthRemoteDataSource.login: iniciando authorizeAndExchangeCode', name: 'auth');
    dev.log('AuthRemoteDataSource.login: issuer=${KeycloakConfig.issuer}', name: 'auth');
    dev.log('AuthRemoteDataSource.login: redirectUri=${KeycloakConfig.redirectUri}', name: 'auth');
    dev.log('AuthRemoteDataSource.login: clientId=${KeycloakConfig.clientId}', name: 'auth');

    AuthorizationTokenResponse? result;
    try {
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
    } on Exception catch (e, stackTrace) {
      dev.log('AuthRemoteDataSource.login: excepción: $e', name: 'auth');
      dev.log('AuthRemoteDataSource.login: stackTrace: $stackTrace', name: 'auth');

      final errorStr = e.toString().toLowerCase();

      // Usuario canceló el login
      if (errorStr.contains('cancel') || errorStr.contains('user_cancelled')) {
        throw Exception('Login cancelado por el usuario');
      }

      // Error de estado no almacenado - típico cuando el callback no puede recuperar el estado
      if (errorStr.contains('no stored state') || errorStr.contains('state mismatch')) {
        throw Exception(
          'Error de autenticación: No se pudo completar el flujo OAuth. '
          'Por favor, intente nuevamente.',
        );
      }

      // Resultado nulo
      if (errorStr.contains('null')) {
        throw Exception('No se recibió respuesta del servidor de autenticación');
      }

      rethrow;
    }

    dev.log(
      'AuthRemoteDataSource.login: recibido accessToken=${result?.accessToken != null}, refreshToken=${result?.refreshToken != null}, idToken=${result?.idToken != null}',
      name: 'auth',
    );

    if (result == null) {
      throw Exception('No se recibió respuesta del servidor de autenticación');
    }

    final accessToken = result.accessToken;
    if (accessToken == null) {
      throw Exception('No se recibió access_token');
    }

    final claims = decodeJwt(result.idToken ?? accessToken);
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
    dev.log('AuthRemoteDataSource.refresh: solicitando nuevo token', name: 'auth');
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

    final claims = decodeJwt(result.idToken ?? accessToken);
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
      dev.log('AuthRemoteDataSource.logout: error cerrando sesión remota', name: 'auth');
      // Ignoramos errores silenciosamente; el logout local seguirá.
    }
  }

  UsuarioModel _usuarioFromClaims(Map<String, dynamic> claims) {
    final id = claims['sub']?.toString() ?? 'desconocido';
    final nombre = (claims['name'] ?? claims['preferred_username'] ?? 'usuario')
        .toString();
    final email = (claims['email'] ?? '').toString();
    final roles = _extractRoles(claims);
    final rol = _mapRole(roles);

    return UsuarioModel(
      id: id,
      nombre: nombre,
      email: email.isNotEmpty ? email : nombre,
      rol: rol,
      activo: true,
    );
  }

  List<String> _extractRoles(Map<String, dynamic> claims) {
    final realm = claims['realm_access'];
    if (realm is Map && realm['roles'] is List) {
      return List<String>.from(realm['roles'] as List);
    }

    final resource = claims['resource_access'];
    if (resource is Map && resource.isNotEmpty) {
      final first = (resource.values.first as Map?)?['roles'];
      if (first is List) return List<String>.from(first);
    }
    return const [];
  }

  UserRole _mapRole(List<String> roles) {
    if (roles.contains('admin')) return UserRole.admin;
    if (roles.contains('vendedor')) return UserRole.vendedor;
    if (roles.contains('contador')) return UserRole.contador;
    return UserRole.vendedor;
  }
}
