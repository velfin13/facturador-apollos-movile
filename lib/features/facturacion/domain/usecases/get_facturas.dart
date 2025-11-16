import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/factura.dart';
import '../repositories/factura_repository.dart';

@lazySingleton
class GetFacturas implements UseCase<List<Factura>, NoParams> {
  final FacturaRepository repository;

  GetFacturas(this.repository);

  @override
  Future<Either<Failure, List<Factura>>> call(NoParams params) async {
    return await repository.getFacturas();
  }
}
