import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cliente.dart';
import '../repositories/cliente_repository.dart';

@lazySingleton
class CreateCliente implements UseCase<Cliente, CreateClienteParams> {
  final ClienteRepository repository;

  CreateCliente(this.repository);

  @override
  Future<Either<Failure, Cliente>> call(CreateClienteParams params) async {
    return await repository.createCliente(params.cliente);
  }
}

class CreateClienteParams {
  final Cliente cliente;

  CreateClienteParams({required this.cliente});
}
