import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/factura.dart';

abstract class FacturaRepository {
  Future<Either<Failure, List<Factura>>> getFacturas();
  Future<Either<Failure, Factura>> getFactura(String id);
  Future<Either<Failure, Factura>> createFactura(Factura factura);
  Future<Either<Failure, Unit>> deleteFactura(String id);
}
