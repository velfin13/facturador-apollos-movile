import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection/injection_container.dart';
import '../bloc/cliente_bloc.dart';
import '../widgets/cliente_list_widget.dart';
import 'crear_cliente_page.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClienteBloc>()..add(GetClientesEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clientes'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: BlocBuilder<ClienteBloc, ClienteState>(
          builder: (context, state) {
            if (state is ClienteLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ClienteLoaded) {
              return ClienteListWidget(clientes: state.clientes);
            } else if (state is ClienteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ClienteBloc>().add(GetClientesEvent());
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('No hay datos'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_clientes',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => getIt<ClienteBloc>(),
                  child: const CrearClientePage(),
                ),
              ),
            );

            if (result == true && context.mounted) {
              context.read<ClienteBloc>().add(GetClientesEvent());
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
