/// Configuración de la API
class ApiConfig {
  // URL base de la API
  static const String baseUrl = 'http://192.168.0.106:5117/api';

  // Endpoints
  static const String clientes = '/Clientes';
  static const String productos = '/Product';
  static const String ventas = '/Ventas';
  static const String inventario = '/Inventario';
  static const String reportes = '/Reportes';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, dynamic> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
