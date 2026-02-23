import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paged_result.dart';
import '../entities/factura.dart';

abstract class FacturaRepository {
  Future<Either<Failure, PagedResult<Factura>>> getFacturas({
    String? search,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int page = 0,
    int size = 20,
  });
  Future<Either<Failure, Factura>> getFactura(String id);
  Future<Either<Failure, Factura>> createFactura(Factura factura);
  Future<Either<Failure, Unit>> deleteFactura(String id);
}
