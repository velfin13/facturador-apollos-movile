import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

class GetProductosParams {
  final String? activo;

  const GetProductosParams({this.activo = 'S'});
}

@lazySingleton
class GetProductos implements UseCase<List<Producto>, GetProductosParams> {
  final ProductoRepository repository;

  GetProductos(this.repository);

  @override
  Future<Either<Failure, List<Producto>>> call(
    GetProductosParams params,
  ) async {
    return await repository.getProductos(activo: params.activo);
  }
}
