import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paged_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cliente.dart';
import '../repositories/cliente_repository.dart';

class GetClientesParams {
  final String? search;
  final int page;
  final int size;

  const GetClientesParams({
    this.search,
    this.page = 0,
    this.size = 20,
  });
}

@lazySingleton
class GetClientes implements UseCase<PagedResult<Cliente>, GetClientesParams> {
  final ClienteRepository repository;

  GetClientes(this.repository);

  @override
  Future<Either<Failure, PagedResult<Cliente>>> call(
    GetClientesParams params,
  ) async {
    return await repository.getClientes(
      search: params.search,
      page: params.page,
      size: params.size,
    );
  }
}
