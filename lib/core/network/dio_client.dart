import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../auth/auth_token_manager.dart';
import 'api_config.dart';

/// Cliente HTTP basado en Dio
@lazySingleton
class DioClient {
  late final Dio _dio;
  final AuthTokenManager _authTokenManager;

  DioClient(this._authTokenManager) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.headers,
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_authTokenManager, _dio));

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

  // Métodos helper
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

  _AuthInterceptor(this._tokenManager, this._dio);

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
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final retried = err.requestOptions.extra['retried'] == true;

    if (status == 401 && !retried) {
      final token = await _tokenManager.getValidAccessToken();
      if (token != null && token.isNotEmpty) {
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $token';
        requestOptions.extra['retried'] = true;
        try {
          final clone = await _dio.fetch(requestOptions);
          return handler.resolve(clone);
        } catch (_) {
          // si falla, dejamos pasar el error original
        }
      }
    }

    handler.next(err);
  }
}
