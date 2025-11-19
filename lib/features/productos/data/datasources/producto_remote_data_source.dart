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

      // La API devuelve: {success, message, data, errors}
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

      // La API devuelve: {success, message, data, errors}
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
      // 1. Crear el producto (sin stock) - El ID lo genera el backend
      final data = {
        // NO enviar idSysInProducto - lo genera el backend
        'idSysPeriodo': _periodoManager.periodoActual,
        'descripcion': producto.descripcion,
        'idSysInMedida': producto.medida,
        'costo': producto.costo,
        'iva': producto.iva,
        'precio1': producto.precio1,
        'precio2': producto.precio2,
        'precio3': producto.precio3,
        'barra': producto.barra,
        'activo': producto.activo ? 'S' : 'N',
      };

      final response = await _dioClient.post('/Productos', data: data);

      // La API devuelve: {success, message, data, errors}
      if (response.data is Map && response.data['data'] != null) {
        final productoCreado = ProductoModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );

        // 2. Si tiene stock inicial, ajustar el inventario
        if (producto.stock > 0) {
          try {
            await _dioClient.post(
              '/Inventario/ajuste',
              data: {
                'idSysPeriodo': _periodoManager.periodoActual,
                'idSysInProducto':
                    productoCreado.id, // Usar el ID generado por el backend
                'idSysInBodega': null, // Bodega por defecto
                'cantidadAjuste': producto.stock.toDouble(),
                'tipoAjuste': 'ENTRADA',
                'motivo': 'Stock inicial',
              },
            );
          } catch (e) {
            // Si falla el ajuste de stock, el producto ya fue creado
            // Solo logueamos el error pero no fallamos la operación
            print('Advertencia: No se pudo ajustar el stock inicial: $e');
          }
        }

        return productoCreado;
      }
      throw ApiException('Error al crear producto');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ProductoModel> updateProducto(ProductoModel producto) async {
    try {
      final data = {
        'idSysInProducto': producto.id,
        'idSysPeriodo': producto.periodo,
        'descripcion': producto.descripcion,
        'idSysInMedida': producto.medida,
        'costo': producto.costo,
        'iva': producto.iva,
        'precio1': producto.precio1,
        'precio2': producto.precio2,
        'precio3': producto.precio3,
        'barra': producto.barra,
        'activo': producto.activo ? 'S' : 'N',
      };

      final response = await _dioClient.put(
        '/Productos/${producto.periodo}/${producto.id}',
        data: data,
      );

      // La API devuelve: {success, message, data, errors}
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
