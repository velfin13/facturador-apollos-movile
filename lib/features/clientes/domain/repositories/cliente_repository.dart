import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cliente.dart';

abstract class ClienteRepository {
  Future<Either<Failure, List<Cliente>>> getClientes();
  Future<Either<Failure, Cliente>> getCliente(String id);
  Future<Either<Failure, Cliente>> createCliente(Cliente cliente);
  Future<Either<Failure, Cliente>> updateCliente(Cliente cliente);
  Future<Either<Failure, Unit>> deleteCliente(String id);
}
