import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection/injection_container.dart';
import '../bloc/factura_bloc.dart';
import '../widgets/factura_list_widget.dart';

class FacturasPage extends StatelessWidget {
  const FacturasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FacturaBloc>()..add(GetFacturasEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Facturas'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: BlocBuilder<FacturaBloc, FacturaState>(
          builder: (context, state) {
            if (state is FacturaLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FacturaLoaded) {
              return FacturaListWidget(facturas: state.facturas);
            } else if (state is FacturaError) {
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
                        context.read<FacturaBloc>().add(GetFacturasEvent());
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Text('Presiona el botón para cargar facturas'),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_facturas',
          onPressed: () {
            // TODO: Navegar a página de crear factura
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
