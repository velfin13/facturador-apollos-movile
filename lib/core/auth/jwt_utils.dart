import 'dart:convert';

Map<String, dynamic> decodeJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw const FormatException('Token inválido');

  final payload = parts[1];
  var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
  switch (normalized.length % 4) {
    case 2:
      normalized += '==';
      break;
    case 3:
      normalized += '=';
      break;
  }
  final decoded = utf8.decode(base64.decode(normalized));
  final data = jsonDecode(decoded);
  if (data is Map<String, dynamic>) return data;
  throw const FormatException('Payload no es JSON');
}

DateTime? expirationFromClaims(Map<String, dynamic> claims) {
  final exp = claims['exp'];
  if (exp is int) {
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }
  return null;
}
