part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Usuario usuario;

  const AuthAuthenticated(this.usuario);

  @override
  List<Object> get props => [usuario];
}

class AuthUnauthenticated extends AuthState {
  final String? errorMessage;

  const AuthUnauthenticated({this.errorMessage});

  @override
  List<Object> get props => [errorMessage ?? ''];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
