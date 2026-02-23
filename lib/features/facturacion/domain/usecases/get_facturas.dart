import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paged_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/factura.dart';
import '../repositories/factura_repository.dart';

class GetFacturasParams {
  final String? search;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final int page;
  final int size;

  const GetFacturasParams({
    this.search,
    this.fechaDesde,
    this.fechaHasta,
    this.page = 0,
    this.size = 20,
  });
}

@lazySingleton
class GetFacturas implements UseCase<PagedResult<Factura>, GetFacturasParams> {
  final FacturaRepository repository;

  GetFacturas(this.repository);

  @override
  Future<Either<Failure, PagedResult<Factura>>> call(
    GetFacturasParams params,
  ) async {
    return await repository.getFacturas(
      search: params.search,
      fechaDesde: params.fechaDesde,
      fechaHasta: params.fechaHasta,
      page: params.page,
      size: params.size,
    );
  }
}
