import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/producto.dart';

abstract class ProductoRepository {
  Future<Either<Failure, List<Producto>>> getProductos({String? activo});
  Future<Either<Failure, Producto>> getProducto(String id);
  Future<Either<Failure, Producto>> createProducto(Producto producto);
  Future<Either<Failure, Producto>> updateProducto(Producto producto);
  Future<Either<Failure, Unit>> deleteProducto(String id);
}
