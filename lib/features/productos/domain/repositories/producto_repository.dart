import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paged_result.dart';
import '../entities/producto.dart';

abstract class ProductoRepository {
  Future<Either<Failure, PagedResult<Producto>>> getProductos({
    String? filtro,
    String? activo,
    int page = 0,
    int size = 20,
  });
  Future<Either<Failure, Producto>> getProducto(String id);
  Future<Either<Failure, Producto>> createProducto(Producto producto);
  Future<Either<Failure, Producto>> updateProducto(Producto producto);
  Future<Either<Failure, Unit>> deleteProducto(String id);
}
