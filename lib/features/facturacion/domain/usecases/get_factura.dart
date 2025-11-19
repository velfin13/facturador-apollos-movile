import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/factura.dart';
import '../repositories/factura_repository.dart';

@injectable
class GetFactura implements UseCase<Factura, String> {
  final FacturaRepository repository;

  GetFactura(this.repository);

  @override
  Future<Either<Failure, Factura>> call(String id) async {
    return await repository.getFactura(id);
  }
}
