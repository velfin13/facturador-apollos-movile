import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Login loginUseCase;
  final Logout logoutUseCase;
  final GetCurrentUser getCurrentUser;
  final TokenStorage tokenStorage;

  Usuario? _usuarioActual;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUser,
    required this.tokenStorage,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    on<SelectRoleEvent>(_onSelectRole);
    on<SwitchRoleEvent>(_onSwitchRole);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    dev.log('AuthBloc: LoginEvent recibido', name: 'auth');
    emit(AuthLoading());

    final failureOrUser = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    failureOrUser.fold(
      (failure) {
        dev.log('AuthBloc: login fallo ${failure.message}', name: 'auth');
        emit(AuthUnauthenticated(errorMessage: failure.message));
      },
      (usuario) {
        dev.log(
          'AuthBloc: login ok usuario=${usuario.email}, roles=${usuario.roles}',
          name: 'auth',
        );
        _usuarioActual = usuario;
        _emitAuthState(usuario, emit);
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    dev.log('AuthBloc: LogoutEvent', name: 'auth');
    _usuarioActual = null;
    await logoutUseCase(NoParams());
    emit(const AuthUnauthenticated());
  }

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    dev.log('AuthBloc: CheckAuthEvent', name: 'auth');
    emit(AuthLoading());

    final failureOrUser = await getCurrentUser(NoParams());

    failureOrUser.fold((_) => emit(const AuthUnauthenticated()), (usuario) {
      if (usuario != null) {
        dev.log(
          'AuthBloc: usuario en cache ${usuario.email}, roles=${usuario.roles}',
          name: 'auth',
        );
        _usuarioActual = usuario;
        _emitAuthState(usuario, emit);
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  void _emitAuthState(Usuario usuario, Emitter<AuthState> emit) {
    // Si no tiene roles validos asignados
    if (usuario.roles.isEmpty) {
      emit(AuthNoRolesAssigned(usuario));
      return;
    }

    // Si tiene multiples roles y no ha seleccionado uno
    if (usuario.tieneMultiplesRoles && !usuario.tieneRolSeleccionado) {
      emit(AuthRoleSelectionRequired(usuario));
      return;
    }

    // Un solo rol o ya seleccionado
    final usuarioConRol = usuario.tieneRolSeleccionado
        ? usuario
        : usuario.conRolActivo(usuario.roles.first);
    emit(AuthAuthenticated(usuarioConRol));
  }

  Future<void> _onSelectRole(
    SelectRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    dev.log('AuthBloc: SelectRoleEvent rol=${event.rol}', name: 'auth');

    if (_usuarioActual == null) {
      emit(const AuthUnauthenticated(errorMessage: 'Sesion expirada'));
      return;
    }

    if (!_usuarioActual!.roles.contains(event.rol)) {
      emit(const AuthError('Rol no permitido para este usuario'));
      return;
    }

    await tokenStorage.saveSelectedRole(event.rol.name);

    final usuarioConRol = _usuarioActual!.conRolActivo(event.rol);
    _usuarioActual = usuarioConRol;

    emit(AuthAuthenticated(usuarioConRol));
  }

  Future<void> _onSwitchRole(
    SwitchRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    dev.log('AuthBloc: SwitchRoleEvent nuevoRol=${event.nuevoRol}', name: 'auth');

    if (_usuarioActual == null) {
      emit(const AuthUnauthenticated(errorMessage: 'Sesion expirada'));
      return;
    }

    if (!_usuarioActual!.roles.contains(event.nuevoRol)) {
      emit(const AuthError('Rol no permitido para este usuario'));
      return;
    }

    await tokenStorage.saveSelectedRole(event.nuevoRol.name);

    final usuarioConRol = _usuarioActual!.conRolActivo(event.nuevoRol);
    _usuarioActual = usuarioConRol;

    emit(AuthAuthenticated(usuarioConRol));
  }
}
