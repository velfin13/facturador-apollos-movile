import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/periodo_manager.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/producto_model.dart';

abstract class ProductoRemoteDataSource {
  Future<List<ProductoModel>> getProductos({
    String? filtro,
    bool soloActivos = true,
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
  Future<List<ProductoModel>> getProductos({
    String? filtro,
    bool soloActivos = true,
  }) async {
    try {
      final response = await _dioClient.get(
        '/Productos',
        queryParameters: {
          'periodo': _periodoManager.periodoActual,
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
          'soloActivos': soloActivos,
        },
      );

      if (response.data is Map && response.data['data'] != null) {
        final data = response.data['data'];
        if (data is List) {
          return data
              .map(
                (json) => ProductoModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ProductoModel> getProducto(String id) async {
    try {
      final response = await _dioClient.get(
        '/Productos/${_periodoManager.periodoActual}/$id',
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
      // Agregar el periodo actual si no viene
      data['idSysPeriodo'] = producto.idSysPeriodo ?? _periodoManager.periodoActual;

      final response = await _dioClient.post('/Productos', data: data);

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
      final data = producto.toJson();
      data['idSysInProducto'] = producto.id;

      final response = await _dioClient.put(
        '/Productos/${producto.idSysPeriodo}/${producto.id}',
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
        '/Productos/${_periodoManager.periodoActual}/$id',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
