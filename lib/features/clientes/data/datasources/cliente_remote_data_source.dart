import 'package:injectable/injectable.dart';
import '../models/cliente_model.dart';

abstract class ClienteRemoteDataSource {
  Future<List<ClienteModel>> getClientes();
  Future<ClienteModel> getCliente(String id);
  Future<ClienteModel> createCliente(ClienteModel cliente);
  Future<ClienteModel> updateCliente(ClienteModel cliente);
  Future<void> deleteCliente(String id);
}

@LazySingleton(as: ClienteRemoteDataSource)
class ClienteRemoteDataSourceImpl implements ClienteRemoteDataSource {
  // Lista en memoria para simular base de datos
  final List<ClienteModel> _clientes = [
    ClienteModel(
      id: '1',
      nombre: 'Juan Pérez',
      razonSocial: 'Pérez Comercio',
      identificacion: '1234567890001',
      email: 'juan@example.com',
      telefono: '0991234567',
      direccion: 'Av. Principal 123',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ClienteModel(
      id: '2',
      nombre: 'María González',
      identificacion: '9876543210001',
      email: 'maria@example.com',
      telefono: '0987654321',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 15)),
    ),
    ClienteModel(
      id: '3',
      nombre: 'Empresa XYZ S.A.',
      razonSocial: 'XYZ Compañía Anónima',
      identificacion: '1234567890002',
      email: 'contacto@xyz.com',
      telefono: '022345678',
      direccion: 'Edificio Central, Piso 5',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 60)),
    ),
  ];

  @override
  Future<List<ClienteModel>> getClientes() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.from(_clientes);
  }

  @override
  Future<ClienteModel> getCliente(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _clientes.firstWhere((c) => c.id == id);
  }

  @override
  Future<ClienteModel> createCliente(ClienteModel cliente) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _clientes.add(cliente);
    return cliente;
  }

  @override
  Future<ClienteModel> updateCliente(ClienteModel cliente) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _clientes.indexWhere((c) => c.id == cliente.id);
    if (index != -1) {
      _clientes[index] = cliente;
    }
    return cliente;
  }

  @override
  Future<void> deleteCliente(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _clientes.removeWhere((c) => c.id == id);
  }
}
