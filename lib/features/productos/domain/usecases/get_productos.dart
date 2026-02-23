import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paged_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

class GetProductosParams {
  final String? filtro;
  final String? activo;
  final int page;
  final int size;

  const GetProductosParams({
    this.filtro,
    this.activo = 'S',
    this.page = 0,
    this.size = 20,
  });
}

@lazySingleton
class GetProductos implements UseCase<PagedResult<Producto>, GetProductosParams> {
  final ProductoRepository repository;

  GetProductos(this.repository);

  @override
  Future<Either<Failure, PagedResult<Producto>>> call(
    GetProductosParams params,
  ) async {
    return await repository.getProductos(
      filtro: params.filtro,
      activo: params.activo,
      page: params.page,
      size: params.size,
    );
  }
}
