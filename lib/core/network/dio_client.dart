import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../auth/auth_token_manager.dart';
import '../auth/session_expired_notifier.dart';
import 'api_config.dart';

/// Cliente HTTP basado en Dio
@lazySingleton
class DioClient {
  late final Dio _dio;
  final AuthTokenManager _authTokenManager;

  DioClient(this._authTokenManager, SessionExpiredNotifier sessionExpiredNotifier) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.headers,
      ),
    );

    _dio.interceptors.add(
      _AuthInterceptor(_authTokenManager, _dio, sessionExpiredNotifier),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  final AuthTokenManager _tokenManager;
  final Dio _dio;
  final SessionExpiredNotifier _notifier;

  _AuthInterceptor(this._tokenManager, this._dio, this._notifier);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenManager.getValidAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(requestOptions: options, error: e),
        true,
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final retried = err.requestOptions.extra['retried'] == true;

    if (status == 401 && !retried) {
      // Primer 401: intentar refrescar el token
      final token = await _tokenManager.getValidAccessToken();
      if (token != null && token.isNotEmpty) {
        // Refresh exitoso → reintentar la request original
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $token';
        opts.extra['retried'] = true;
        try {
          final clone = await _dio.fetch(opts);
          return handler.resolve(clone);
        } catch (_) {
          // Reintento también falló con token fresco → sesión inválida
          _notifier.notify();
        }
      } else {
        // No hay token válido (refresh falló, sesión limpiada)
        _notifier.notify();
      }
    } else if (status == 401 && retried) {
      // Segundo 401 consecutivo → sesión definitivamente expirada
      _notifier.notify();
    }

    handler.next(err);
  }
}
