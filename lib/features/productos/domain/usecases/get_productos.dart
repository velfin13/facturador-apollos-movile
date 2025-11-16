import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

@lazySingleton
class GetProductos implements UseCase<List<Producto>, NoParams> {
  final ProductoRepository repository;

  GetProductos(this.repository);

  @override
  Future<Either<Failure, List<Producto>>> call(NoParams params) async {
    return await repository.getProductos();
  }
}
