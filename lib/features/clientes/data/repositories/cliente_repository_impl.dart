import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../datasources/cliente_remote_data_source.dart';
import '../models/cliente_model.dart';

@LazySingleton(as: ClienteRepository)
class ClienteRepositoryImpl implements ClienteRepository {
  final ClienteRemoteDataSource remoteDataSource;

  ClienteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Cliente>>> getClientes() async {
    try {
      final clientes = await remoteDataSource.getClientes();
      return Right(clientes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cliente>> getCliente(String id) async {
    try {
      final cliente = await remoteDataSource.getCliente(id);
      return Right(cliente);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cliente>> createCliente(Cliente cliente) async {
    try {
      final clienteModel = ClienteModel.fromEntity(cliente);
      final result = await remoteDataSource.createCliente(clienteModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cliente>> updateCliente(Cliente cliente) async {
    try {
      final clienteModel = ClienteModel.fromEntity(cliente);
      final result = await remoteDataSource.updateCliente(clienteModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCliente(String id) async {
    try {
      await remoteDataSource.deleteCliente(id);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
