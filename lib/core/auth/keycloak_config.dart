/// Configuración de Keycloak.
/// Rellena estos valores con los datos del realm cuando los tengas.
class KeycloakConfig {
  /// Ejemplo: https://keycloak.midominio.com/realms/mi-realm
  static const String issuer = 'https://keycloak.uemjava.com/realms/sri-facturador';

  /// ID de cliente público configurado en Keycloak.
  static const String clientId = 'flutter-app';

  /// URI de redirección registrada (Android/iOS/web). Ej: com.apollos.facturador://oauthredirect
  static const String redirectUri = 'com.apollos.facturador://oauthredirect';

  /// URI de redirección tras logout (opcional si no la usas en web).
  static const String postLogoutRedirectUri = 'com.apollos.facturador://oauthredirect';

  /// Alcances solicitados.
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
  ];
}
