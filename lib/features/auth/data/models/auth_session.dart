import 'usuario_model.dart';

class AuthSession {
  final UsuarioModel usuario;
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime? accessTokenExpiry;

  const AuthSession({
    required this.usuario,
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.accessTokenExpiry,
  });

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? accessTokenExpiry,
    UsuarioModel? usuario,
  }) {
    return AuthSession(
      usuario: usuario ?? this.usuario,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      idToken: idToken ?? this.idToken,
      accessTokenExpiry: accessTokenExpiry ?? this.accessTokenExpiry,
    );
  }
}
