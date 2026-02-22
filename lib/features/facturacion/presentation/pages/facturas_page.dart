import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection/injection_container.dart';
import '../../../clientes/presentation/bloc/cliente_bloc.dart';
import '../../../productos/presentation/bloc/producto_bloc.dart';
import '../bloc/factura_bloc.dart';
import '../widgets/factura_list_widget.dart';
import 'crear_factura_page.dart';

class FacturasPage extends StatelessWidget {
  const FacturasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FacturaBloc>()..add(GetFacturasEvent()),
      child: Scaffold(
        body: BlocBuilder<FacturaBloc, FacturaState>(
          buildWhen: (prev, curr) =>
              curr is FacturaLoading ||
              curr is FacturaLoaded ||
              curr is FacturaError,
          builder: (context, state) {
            if (state is FacturaLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FacturaLoaded) {
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<FacturaBloc>().add(GetFacturasEvent()),
                child: FacturaListWidget(facturas: state.facturas),
              );
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
          onPressed: () async {
            final facturaBloc = context.read<FacturaBloc>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => getIt<ClienteBloc>()),
                    BlocProvider(create: (_) => getIt<ProductoBloc>()),
                    BlocProvider.value(value: facturaBloc),
                  ],
                  child: const CrearFacturaPage(),
                ),
              ),
            );
            if (result == true && context.mounted) {
              facturaBloc.add(GetFacturasEvent());
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
