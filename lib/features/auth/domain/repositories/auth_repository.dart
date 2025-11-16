import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/usuario.dart';

abstract class AuthRepository {
  Future<Either<Failure, Usuario>> login(String email, String password);
  Future<Either<Failure, Unit>> logout();
  Future<Either<Failure, Usuario?>> getCurrentUser();
}
