import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paged_result.dart';
import '../../domain/entities/factura.dart';
import '../../domain/repositories/factura_repository.dart';
import '../datasources/factura_local_data_source.dart';
import '../datasources/factura_remote_data_source.dart';
import '../models/factura_model.dart';

@LazySingleton(as: FacturaRepository)
class FacturaRepositoryImpl implements FacturaRepository {
  final FacturaRemoteDataSource remoteDataSource;
  final FacturaLocalDataSource localDataSource;

  FacturaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, PagedResult<Factura>>> getFacturas({
    String? search,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final paged = await remoteDataSource.getFacturas(
        search: search,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        page: page,
        size: size,
      );
      return Right(PagedResult<Factura>(
        items: paged.items,
        total: paged.total,
        page: paged.page,
        size: paged.size,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Factura>> getFactura(String id) async {
    try {
      final factura = await remoteDataSource.getFactura(id);
      return Right(factura);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Factura>> createFactura(Factura factura) async {
    try {
      final facturaModel = FacturaModel.fromEntity(factura);
      final result = await remoteDataSource.createFactura(facturaModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFactura(String id) async {
    try {
      await remoteDataSource.deleteFactura(id);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
