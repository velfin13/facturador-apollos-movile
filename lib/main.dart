import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/auth/session_expired_notifier.dart';
import 'core/theme/app_theme.dart';
import 'injection/injection_container.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/clientes/presentation/bloc/cliente_bloc.dart';
import 'features/productos/presentation/bloc/producto_bloc.dart';
import 'features/facturacion/presentation/bloc/factura_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/role_selection_page.dart';
import 'features/auth/presentation/pages/no_roles_page.dart';
import 'features/auth/presentation/pages/negocio_gate_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(CheckAuthEvent())),
        BlocProvider(create: (_) => getIt<ClienteBloc>()),
        BlocProvider(create: (_) => getIt<ProductoBloc>()),
        BlocProvider(create: (_) => getIt<FacturaBloc>()),
      ],
      child: MaterialApp(
        title: 'Facturador',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AppRoot(),
      ),
    );
  }
}

/// Widget raíz de la app. Es hijo de [MultiBlocProvider], por lo que puede
/// acceder al [AuthBloc] y escuchar el [SessionExpiredNotifier].
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final StreamSubscription<void> _sessionExpiredSub;

  @override
  void initState() {
    super.initState();
    _sessionExpiredSub = getIt<SessionExpiredNotifier>()
        .onSessionExpired
        .listen((_) {
          if (mounted) {
            context.read<AuthBloc>().add(LogoutEvent());
          }
        });
  }

  @override
  void dispose() {
    _sessionExpiredSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        debugPrint('AuthState changed to: ${state.runtimeType}');
        if (state is AuthUnauthenticated && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state is AuthUnauthenticated) {
          // Limpiar cualquier snackbar o dialog pendiente al cerrar sesión
          ScaffoldMessenger.of(context).clearSnackBars();
        }
      },
      builder: (context, state) {
        if (state is AuthNoRolesAssigned) {
          return NoRolesPage(usuario: state.usuario);
        }
        if (state is AuthRoleSelectionRequired) {
          return RoleSelectionPage(usuario: state.usuario);
        }
        if (state is AuthAuthenticated) {
          if (state.usuario.esCliente) {
            return NegocioGatePage(usuario: state.usuario);
          }
          return HomePage(usuario: state.usuario);
        }
        if (state is AuthUnauthenticated) {
          return const LoginPage();
        }
        // AuthInitial / AuthLoading / AuthError → splash
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  state is AuthLoading ? 'Autenticando...' : 'Cargando...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
