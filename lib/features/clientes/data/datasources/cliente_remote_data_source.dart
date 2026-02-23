import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/models/paged_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/periodo_manager.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/cliente_model.dart';

abstract class ClienteRemoteDataSource {
  Future<PagedResult<ClienteModel>> getClientes({
    String? search,
    int page = 0,
    int size = 20,
  });
  Future<ClienteModel> getCliente(String id);
  Future<ClienteModel> createCliente(ClienteModel cliente);
  Future<ClienteModel> updateCliente(ClienteModel cliente);
  Future<void> deleteCliente(String id);
}

@LazySingleton(as: ClienteRemoteDataSource)
class ClienteRemoteDataSourceImpl implements ClienteRemoteDataSource {
  final DioClient _dioClient;
  final PeriodoManager _periodoManager;

  ClienteRemoteDataSourceImpl(this._dioClient, this._periodoManager);

  @override
  Future<PagedResult<ClienteModel>> getClientes({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        '/Clientes',
        queryParameters: {
          'periodo': _periodoManager.periodoActual,
          if (search != null && search.isNotEmpty) 'filtro': search,
          'page': page,
          'size': size,
        },
      );

      // API devuelve: {success, message, data: {items, total, page, size, hasMore}}
      if (response.data is Map && response.data['data'] is Map) {
        final dataMap = response.data['data'] as Map<String, dynamic>;
        return PagedResult.fromApiData(
          dataMap,
          (json) => ClienteModel.fromJson(json),
        );
      }
      return PagedResult<ClienteModel>(items: [], total: 0, page: page, size: size);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ClienteModel> getCliente(String id) async {
    try {
      final response = await _dioClient.get(
        '/Clientes/${_periodoManager.periodoActual}/$id',
      );

      if (response.data is Map && response.data['data'] != null) {
        return ClienteModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException('No se encontró el cliente');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ClienteModel> createCliente(ClienteModel cliente) async {
    try {
      final data = {
        'idSysPeriodo': _periodoManager.periodoActual,
        'nombre': cliente.nombre,
        'direccion': cliente.direccion,
        'telefono': cliente.telefono,
        'ruc': cliente.ruc,
        'activo': cliente.activo ? 'S' : 'N',
        'ciudad': cliente.ciudad,
        'eMail': cliente.email,
        'tipo': cliente.tipo,
      };

      final response = await _dioClient.post('/Clientes', data: data);

      if (response.data is Map && response.data['data'] != null) {
        return ClienteModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException('Error al crear cliente');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ClienteModel> updateCliente(ClienteModel cliente) async {
    try {
      final data = {
        'idSysFcCliente': cliente.id,
        'idSysPeriodo': cliente.periodo,
        'nombre': cliente.nombre,
        'direccion': cliente.direccion,
        'telefono': cliente.telefono,
        'ruc': cliente.ruc,
        'activo': cliente.activo ? 'S' : 'N',
        'ciudad': cliente.ciudad,
        'eMail': cliente.email,
        'tipo': cliente.tipo,
      };

      final response = await _dioClient.put(
        '/Clientes/${cliente.periodo}/${cliente.id}',
        data: data,
      );

      if (response.data is Map && response.data['data'] != null) {
        return ClienteModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException('Error al actualizar cliente');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteCliente(String id) async {
    try {
      await _dioClient.delete('/Clientes/${_periodoManager.periodoActual}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
