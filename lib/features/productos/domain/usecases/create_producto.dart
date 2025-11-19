import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

@injectable
class CreateProducto implements UseCase<Producto, Producto> {
  final ProductoRepository repository;

  CreateProducto(this.repository);

  @override
  Future<Either<Failure, Producto>> call(Producto producto) async {
    return await repository.createProducto(producto);
  }
}
