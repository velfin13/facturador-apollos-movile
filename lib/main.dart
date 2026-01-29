import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection/injection_container.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/clientes/presentation/bloc/cliente_bloc.dart';
import 'features/productos/presentation/bloc/producto_bloc.dart';
import 'features/facturacion/presentation/bloc/factura_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/home_page.dart';

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: BlocConsumer<AuthBloc, AuthState>(
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
          },
          builder: (context, state) {
            // Usuario autenticado -> Home
            if (state is AuthAuthenticated) {
              return HomePage(usuario: state.usuario);
            }
            // Usuario no autenticado -> Login
            if (state is AuthUnauthenticated) {
              return const LoginPage();
            }
            // Cualquier otro estado (Initial, Loading, Error) -> Splash/Loading
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
        ),
      ),
    );
  }
}
