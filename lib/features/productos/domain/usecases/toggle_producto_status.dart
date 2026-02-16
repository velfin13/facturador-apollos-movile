import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

class ToggleProductoStatusParams {
  final Producto producto;
  final bool activar;

  const ToggleProductoStatusParams({
    required this.producto,
    required this.activar,
  });
}

@injectable
class ToggleProductoStatus
    implements UseCase<Unit, ToggleProductoStatusParams> {
  final ProductoRepository repository;

  ToggleProductoStatus(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ToggleProductoStatusParams params) async {
    final productoActualizado = Producto(
      id: params.producto.id,
      idSysPeriodo: params.producto.idSysPeriodo,
      descripcion: params.producto.descripcion,
      iva: params.producto.iva,
      activo: params.activar ? 'S' : 'N',
      idSysUsuario: params.producto.idSysUsuario,
      tipo: params.producto.tipo,
      idImpuesto: params.producto.idImpuesto,
      precio1: params.producto.precio1,
      precio2: params.producto.precio2,
      precio3: params.producto.precio3,
      barra: params.producto.barra,
      fraccion: params.producto.fraccion,
      idEstadoItem: params.producto.idEstadoItem,
      stock: params.producto.stock,
    );

    final result = await repository.updateProducto(productoActualizado);
    return result.fold((failure) => Left(failure), (_) => const Right(unit));
  }
}
