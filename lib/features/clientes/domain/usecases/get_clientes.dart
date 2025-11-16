import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cliente.dart';
import '../repositories/cliente_repository.dart';

@lazySingleton
class GetClientes implements UseCase<List<Cliente>, NoParams> {
  final ClienteRepository repository;

  GetClientes(this.repository);

  @override
  Future<Either<Failure, List<Cliente>>> call(NoParams params) async {
    return await repository.getClientes();
  }
}
