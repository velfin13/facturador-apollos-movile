import 'dart:developer' as dev;

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, Usuario>> login(String email, String password) async {
    try {
      final session = await remoteDataSource.login(email, password);
      await localDataSource.saveSession(session);
      return Right(session.usuario);
    } catch (e) {
      dev.log('AuthRepositoryImpl.login error: $e', name: 'auth');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      final current = await localDataSource.getSession();
      await remoteDataSource.logout(idTokenHint: current?.idToken);
      await localDataSource.clearSession();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Usuario?>> getCurrentUser() async {
    try {
      final session = await localDataSource.getSession();
      return Right(session?.usuario);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
