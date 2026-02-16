import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/producto.dart';
import '../../domain/usecases/get_productos.dart';
import '../../domain/usecases/create_producto.dart';
import '../../domain/usecases/update_producto.dart';
import '../../domain/usecases/toggle_producto_status.dart';

part 'producto_event.dart';
part 'producto_state.dart';

@injectable
class ProductoBloc extends Bloc<ProductoEvent, ProductoState> {
  final GetProductos getProductos;
  final CreateProducto createProducto;
  final UpdateProducto updateProducto;
  final ToggleProductoStatus toggleProductoStatus;
  String? _activoActual = 'S';

  ProductoBloc({
    required this.getProductos,
    required this.createProducto,
    required this.updateProducto,
    required this.toggleProductoStatus,
  }) : super(ProductoInitial()) {
    on<GetProductosEvent>(_onGetProductos);
    on<CreateProductoEvent>(_onCreateProducto);
    on<UpdateProductoEvent>(_onUpdateProducto);
    on<ToggleProductoStatusEvent>(_onToggleProductoStatus);
  }

  Future<void> _onGetProductos(
    GetProductosEvent event,
    Emitter<ProductoState> emit,
  ) async {
    _activoActual = event.activo;
    emit(ProductoLoading());

    final failureOrProductos = await getProductos(
      GetProductosParams(activo: event.activo),
    );

    failureOrProductos.fold(
      (failure) => emit(ProductoError(failure.message)),
      (productos) => emit(ProductoLoaded(productos)),
    );
  }

  Future<void> _onCreateProducto(
    CreateProductoEvent event,
    Emitter<ProductoState> emit,
  ) async {
    emit(ProductoCreating());

    final failureOrProducto = await createProducto(event.producto);

    failureOrProducto.fold((failure) => emit(ProductoError(failure.message)), (
      producto,
    ) {
      emit(ProductoCreated(producto));
      add(GetProductosEvent(activo: _activoActual));
    });
  }

  Future<void> _onUpdateProducto(
    UpdateProductoEvent event,
    Emitter<ProductoState> emit,
  ) async {
    emit(ProductoUpdating());

    final failureOrProducto = await updateProducto(event.producto);

    failureOrProducto.fold((failure) => emit(ProductoError(failure.message)), (
      producto,
    ) {
      emit(ProductoUpdated(producto));
      add(GetProductosEvent(activo: _activoActual));
    });
  }

  Future<void> _onToggleProductoStatus(
    ToggleProductoStatusEvent event,
    Emitter<ProductoState> emit,
  ) async {
    final failureOrUnit = await toggleProductoStatus(
      ToggleProductoStatusParams(
        producto: event.producto,
        activar: event.activar,
      ),
    );

    await failureOrUnit.fold(
      (failure) async => emit(ProductoError(failure.message)),
      (_) async {
        final message = event.activar
            ? 'Producto activado correctamente'
            : 'Producto desactivado correctamente';
        emit(ProductoStatusUpdated(message));
        add(GetProductosEvent(activo: _activoActual));
      },
    );
  }
}
