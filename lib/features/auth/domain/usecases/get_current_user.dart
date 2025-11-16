import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class GetCurrentUser implements UseCase<Usuario?, NoParams> {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, Usuario?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}
