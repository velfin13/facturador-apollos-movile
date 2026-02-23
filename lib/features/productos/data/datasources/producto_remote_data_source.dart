import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/models/paged_result.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/periodo_manager.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/producto_model.dart';

abstract class ProductoRemoteDataSource {
  Future<PagedResult<ProductoModel>> getProductos({
    String? filtro,
    String? activo,
    int page = 0,
    int size = 20,
  });
  Future<ProductoModel> getProducto(String id);
  Future<ProductoModel> createProducto(ProductoModel producto);
  Future<ProductoModel> updateProducto(ProductoModel producto);
  Future<void> deleteProducto(String id);
}

@LazySingleton(as: ProductoRemoteDataSource)
class ProductoRemoteDataSourceImpl implements ProductoRemoteDataSource {
  final DioClient _dioClient;
  final PeriodoManager _periodoManager;

  ProductoRemoteDataSourceImpl(this._dioClient, this._periodoManager);

  @override
  Future<PagedResult<ProductoModel>> getProductos({
    String? filtro,
    String? activo,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiConfig.productos,
        queryParameters: {
          'periodo': _periodoManager.periodoActual,
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
          if (activo != null) 'activo': activo,
          'page': page,
          'size': size,
        },
      );

      // API devuelve: {success, message, data: {items, total, page, size, hasMore}}
      if (response.data is Map && response.data['data'] is Map) {
        final dataMap = response.data['data'] as Map<String, dynamic>;
        return PagedResult.fromApiData(
          dataMap,
          (json) => ProductoModel.fromJson(json),
        );
      }
      return PagedResult<ProductoModel>(items: [], total: 0, page: page, size: size);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ProductoModel> getProducto(String id) async {
    try {
      final response = await _dioClient.get(
        '${ApiConfig.productos}/${_periodoManager.periodoActual}/$id',
      );

      if (response.data is Map && response.data['data'] != null) {
        return ProductoModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException('Error al obtener producto');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ProductoModel> createProducto(ProductoModel producto) async {
    try {
      final data = producto.toJson();
      data['idSysPeriodo'] =
          producto.idSysPeriodo ?? _periodoManager.periodoActual;

      final response = await _dioClient.post(ApiConfig.productos, data: data);

      if (response.data is Map && response.data['data'] != null) {
        return ProductoModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException('Error al crear producto');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ProductoModel> updateProducto(ProductoModel producto) async {
    try {
      final data = <String, dynamic>{
        'descripcion': producto.descripcion,
        'iva': producto.iva,
        'activo': producto.activo,
        'precio1': producto.precio1,
        'precio2': producto.precio2,
        'precio3': producto.precio3,
        'barra': producto.barra,
        'idImpuesto': producto.idImpuesto,
      }..removeWhere((_, value) => value == null);

      final response = await _dioClient.put(
        '${ApiConfig.productos}/${producto.idSysPeriodo}/${producto.id}',
        data: data,
      );

      if (response.data is Map && response.data['data'] != null) {
        return ProductoModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException('Error al actualizar producto');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteProducto(String id) async {
    try {
      await _dioClient.delete(
        '${ApiConfig.productos}/${_periodoManager.periodoActual}/$id',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
