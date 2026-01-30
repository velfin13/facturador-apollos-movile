part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

class SelectRoleEvent extends AuthEvent {
  final UserRole rol;

  const SelectRoleEvent(this.rol);

  @override
  List<Object> get props => [rol];
}

class SwitchRoleEvent extends AuthEvent {
  final UserRole nuevoRol;

  const SwitchRoleEvent(this.nuevoRol);

  @override
  List<Object> get props => [nuevoRol];
}
