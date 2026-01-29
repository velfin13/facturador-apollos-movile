import 'dart:developer' as dev;

import 'package:injectable/injectable.dart';

import '../../features/auth/data/datasources/auth_data_source.dart';
import '../../features/auth/data/models/auth_session.dart';

@lazySingleton
class AuthTokenManager {
  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;

  AuthTokenManager(this._local, this._remote);

  Future<String?> getValidAccessToken() async {
    final session = await _local.getSession();
    if (session == null) {
      dev.log('AuthTokenManager: no hay sesión guardada', name: 'auth');
      return null;
    }

    if (_isExpired(session)) {
      dev.log('AuthTokenManager: token expirado, intentando refresh', name: 'auth');
      final refreshed = await _tryRefresh(session);
      return refreshed?.accessToken;
    }

    return session.accessToken;
  }

  Future<AuthSession?> _tryRefresh(AuthSession session) async {
    final refreshToken = session.refreshToken;
    if (refreshToken == null) {
      dev.log('AuthTokenManager: no hay refresh token', name: 'auth');
      return session;
    }

    try {
      final refreshed = await _remote.refresh(refreshToken);
      await _local.saveSession(refreshed);
      dev.log('AuthTokenManager: refresh exitoso', name: 'auth');
      return refreshed;
    } catch (e) {
      dev.log('AuthTokenManager: error en refresh: $e', name: 'auth');
      // Si el refresh falla, limpiamos la sesión para forzar un nuevo login
      await _local.clearSession();
      return null;
    }
  }

  bool _isExpired(AuthSession session) {
    final expiry = session.accessTokenExpiry;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
  }
}
