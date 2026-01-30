import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TokenStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyIdToken = 'id_token';
  static const _keyAccessExpiry = 'access_expiry';
  static const _keyUser = 'user';
  static const _keySelectedRole = 'selected_role';

  final FlutterSecureStorage _storage;

  TokenStorage(this._storage);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? accessExpiry,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    if (idToken != null) {
      await _storage.write(key: _keyIdToken, value: idToken);
    }
    if (accessExpiry != null) {
      await _storage.write(
        key: _keyAccessExpiry,
        value: accessExpiry.toIso8601String(),
      );
    }
  }

  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    await _storage.write(key: _keyUser, value: jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> readUserJson() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<String?> get accessToken => _storage.read(key: _keyAccessToken);

  Future<String?> get refreshToken => _storage.read(key: _keyRefreshToken);

  Future<String?> get idToken => _storage.read(key: _keyIdToken);

  Future<DateTime?> get accessExpiry async {
    final raw = await _storage.read(key: _keyAccessExpiry);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveSelectedRole(String role) async {
    await _storage.write(key: _keySelectedRole, value: role);
  }

  Future<String?> get selectedRole => _storage.read(key: _keySelectedRole);

  Future<void> clearSelectedRole() async {
    await _storage.delete(key: _keySelectedRole);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyIdToken);
    await _storage.delete(key: _keyAccessExpiry);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keySelectedRole);
  }
}
