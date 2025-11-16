import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
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

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUser,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final failureOrUser = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    failureOrUser.fold(
      (failure) => emit(AuthError(failure.message)),
      (usuario) => emit(AuthAuthenticated(usuario)),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await logoutUseCase(NoParams());
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    final failureOrUser = await getCurrentUser(NoParams());

    failureOrUser.fold((_) => emit(AuthUnauthenticated()), (usuario) {
      if (usuario != null) {
        emit(AuthAuthenticated(usuario));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }
}
