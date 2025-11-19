import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/factura.dart';
import '../repositories/factura_repository.dart';

@lazySingleton
class CreateFactura implements UseCase<Factura, Factura> {
  final FacturaRepository repository;

  CreateFactura(this.repository);

  @override
  Future<Either<Failure, Factura>> call(Factura factura) async {
    return await repository.createFactura(factura);
  }
}
