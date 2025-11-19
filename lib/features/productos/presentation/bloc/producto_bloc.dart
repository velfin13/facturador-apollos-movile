import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/producto.dart';
import '../../domain/usecases/get_productos.dart';
import '../../domain/usecases/create_producto.dart';

part 'producto_event.dart';
part 'producto_state.dart';

@injectable
class ProductoBloc extends Bloc<ProductoEvent, ProductoState> {
  final GetProductos getProductos;
  final CreateProducto createProducto;

  ProductoBloc({required this.getProductos, required this.createProducto})
    : super(ProductoInitial()) {
    on<GetProductosEvent>(_onGetProductos);
    on<CreateProductoEvent>(_onCreateProducto);
  }

  Future<void> _onGetProductos(
    GetProductosEvent event,
    Emitter<ProductoState> emit,
  ) async {
    emit(ProductoLoading());

    final failureOrProductos = await getProductos(NoParams());

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

    failureOrProducto.fold(
      (failure) => emit(ProductoError(failure.message)),
      (producto) => emit(ProductoCreated(producto)),
    );
  }
}
