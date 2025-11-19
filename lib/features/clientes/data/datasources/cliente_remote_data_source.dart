import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/periodo_manager.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/cliente_model.dart';

abstract class ClienteRemoteDataSource {
  Future<List<ClienteModel>> getClientes({String? filtro});
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
  Future<List<ClienteModel>> getClientes({String? filtro}) async {
    try {
      final response = await _dioClient.get(
        '/Clientes',
        queryParameters: {
          'periodo': _periodoManager.periodoActual,
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );

      // La API devuelve: {success, message, data, errors}
      if (response.data is Map && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((json) => ClienteModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
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

      // La API devuelve: {success, message, data, errors}
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

      final response = await _dioClient.post('/Clientes', data: data);

      // La API devuelve: {success, message, data, errors}
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

      // La API devuelve: {success, message, data, errors}
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
