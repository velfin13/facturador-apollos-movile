import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cliente.dart';
import '../repositories/cliente_repository.dart';

@lazySingleton
class UpdateCliente implements UseCase<Cliente, UpdateClienteParams> {
  final ClienteRepository repository;

  UpdateCliente(this.repository);

  @override
  Future<Either<Failure, Cliente>> call(UpdateClienteParams params) async {
    return await repository.updateCliente(params.cliente);
  }
}

class UpdateClienteParams {
  final Cliente cliente;
  UpdateClienteParams({required this.cliente});
}
