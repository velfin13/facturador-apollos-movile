import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection/injection_container.dart';
import '../bloc/producto_bloc.dart';
import '../widgets/producto_list_widget.dart';

class ProductosPage extends StatelessWidget {
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductoBloc>()..add(GetProductosEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Productos'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: BlocBuilder<ProductoBloc, ProductoState>(
          builder: (context, state) {
            if (state is ProductoLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductoLoaded) {
              return ProductoListWidget(productos: state.productos);
            } else if (state is ProductoError) {
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
                        context.read<ProductoBloc>().add(GetProductosEvent());
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
          onPressed: () {
            // TODO: Navegar a crear producto
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Crear producto - Próximamente')),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
