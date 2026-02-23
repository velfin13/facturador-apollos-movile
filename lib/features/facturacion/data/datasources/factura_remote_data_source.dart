import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/models/paged_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/periodo_manager.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/factura_model.dart';

abstract class FacturaRemoteDataSource {
  Future<PagedResult<FacturaModel>> getFacturas({
    String? search,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int page = 0,
    int size = 20,
  });
  Future<FacturaModel> getFactura(String id);
  Future<FacturaModel> createFactura(FacturaModel factura);
  Future<void> deleteFactura(String id, {String? motivo});
}

@LazySingleton(as: FacturaRemoteDataSource)
class FacturaRemoteDataSourceImpl implements FacturaRemoteDataSource {
  final DioClient _dioClient;
  final PeriodoManager _periodoManager;

  FacturaRemoteDataSourceImpl(this._dioClient, this._periodoManager);

  @override
  Future<PagedResult<FacturaModel>> getFacturas({
    String? search,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        '/Ventas',
        queryParameters: {
          'periodo': _periodoManager.periodoActual,
          if (search != null && search.isNotEmpty) 'search': search,
          if (fechaDesde != null) 'fechaDesde': fechaDesde.toIso8601String(),
          if (fechaHasta != null) 'fechaHasta': fechaHasta.toIso8601String(),
          'page': page,
          'size': size,
        },
      );

      // API devuelve: {success, message, data: {items, total, page, size, hasMore}}
      if (response.data is Map && response.data['data'] is Map) {
        final dataMap = response.data['data'] as Map<String, dynamic>;
        return PagedResult.fromApiData(
          dataMap,
          (json) => FacturaModel.fromJson(json),
        );
      }
      return PagedResult<FacturaModel>(items: [], total: 0, page: page, size: size);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<FacturaModel> getFactura(String id) async {
    try {
      final response = await _dioClient.get(
        '/Ventas/${_periodoManager.periodoActual}/$id',
      );

      if (response.data is Map && response.data['data'] != null) {
        return FacturaModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException('Error al obtener factura');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<FacturaModel> createFactura(FacturaModel factura) async {
    try {
      final periodo = int.tryParse(_periodoManager.periodoActual) ?? 1;
      final data = {
        'idSysPeriodo': periodo,
        'tipo': factura.tipo ?? 'FV',
        'fecha': factura.fecha.toIso8601String(),
        'idSysFcCliente': int.tryParse(factura.clienteId) ?? 0,
        'observacion': factura.observacion,
        'detalles': factura.items.map((item) {
          final cantidad = item.cantidad.toInt();
          return {
            'idSysInProducto': int.tryParse(item.productoId) ?? 0,
            'cantidad': cantidad,
            'cantidadF': cantidad,
            'valor': item.valor,
            'descuentoPorcentaje': item.descuentoPorcentaje,
            'idSysInBodega': int.tryParse(item.bodegaId ?? '0') ?? 0,
          };
        }).toList(),
        'formasPago': factura.formasPago.map((fp) {
          return {
            'idSysFcFormaPago': int.tryParse(fp.formaPagoId) ?? 1,
            'idSysPeriodo': periodo,
            'valor': fp.valor,
            'numero': fp.numero,
            'referencia': fp.referencia,
            'fechaVence': fp.fechaVence?.toIso8601String(),
          };
        }).toList(),
      };

      final response = await _dioClient.post('/Ventas', data: data);

      if (response.data is Map && response.data['data'] != null) {
        return FacturaModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException('Error al crear venta');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteFactura(String id, {String? motivo}) async {
    try {
      await _dioClient.delete(
        '/Ventas/${_periodoManager.periodoActual}/$id',
        queryParameters: {
          if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
