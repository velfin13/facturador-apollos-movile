import 'package:dio/dio.dart';

/// Convierte excepciones de Dio a mensajes legibles
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  static ApiException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Tiempo de espera agotado. Por favor, intente nuevamente.',
          error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response);

      case DioExceptionType.cancel:
        return ApiException('Solicitud cancelada.');

      case DioExceptionType.connectionError:
        return ApiException(
          'Error de conexión. Verifique su conexión a internet.',
        );

      case DioExceptionType.badCertificate:
        return ApiException('Error de certificado SSL.');

      case DioExceptionType.unknown:
        return ApiException(
          'Error desconocido. Por favor, intente nuevamente.',
        );
    }
  }

  static ApiException _handleStatusCode(Response? response) {
    final statusCode = response?.statusCode;

    switch (statusCode) {
      case 400:
        return ApiException(
          'Solicitud inválida: ${_getErrorMessage(response)}',
          statusCode,
        );
      case 401:
        return ApiException(
          'No autorizado. Inicie sesión nuevamente.',
          statusCode,
        );
      case 403:
        return ApiException('Acceso denegado.', statusCode);
      case 404:
        return ApiException('Recurso no encontrado.', statusCode);
      case 500:
        return ApiException('Error interno del servidor.', statusCode);
      case 503:
        return ApiException('Servicio no disponible.', statusCode);
      default:
        return ApiException(
          'Error del servidor: ${_getErrorMessage(response)}',
          statusCode,
        );
    }
  }

  static String _getErrorMessage(Response? response) {
    try {
      if (response?.data is Map) {
        final data = response?.data as Map<String, dynamic>;
        return data['message'] ??
            data['error'] ??
            data['title'] ??
            'Error desconocido';
      }
      return response?.statusMessage ?? 'Error desconocido';
    } catch (e) {
      return 'Error al procesar respuesta';
    }
  }

  @override
  String toString() => message;
}
