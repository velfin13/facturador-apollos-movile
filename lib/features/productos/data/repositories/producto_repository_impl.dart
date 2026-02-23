import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paged_result.dart';
import '../../domain/entities/producto.dart';
import '../../domain/repositories/producto_repository.dart';
import '../datasources/producto_remote_data_source.dart';
import '../models/producto_model.dart';

@LazySingleton(as: ProductoRepository)
class ProductoRepositoryImpl implements ProductoRepository {
  final ProductoRemoteDataSource remoteDataSource;

  ProductoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PagedResult<Producto>>> getProductos({
    String? filtro,
    String? activo,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final paged = await remoteDataSource.getProductos(
        filtro: filtro,
        activo: activo,
        page: page,
        size: size,
      );
      return Right(PagedResult<Producto>(
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
  Future<Either<Failure, Producto>> getProducto(String id) async {
    try {
      final producto = await remoteDataSource.getProducto(id);
      return Right(producto);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Producto>> createProducto(Producto producto) async {
    try {
      final productoModel = ProductoModel.fromEntity(producto);
      final result = await remoteDataSource.createProducto(productoModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Producto>> updateProducto(Producto producto) async {
    try {
      final productoModel = ProductoModel.fromEntity(producto);
      final result = await remoteDataSource.updateProducto(productoModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProducto(String id) async {
    try {
      await remoteDataSource.deleteProducto(id);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
