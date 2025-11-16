import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/producto.dart';
import '../../domain/usecases/get_productos.dart';

part 'producto_event.dart';
part 'producto_state.dart';

@injectable
class ProductoBloc extends Bloc<ProductoEvent, ProductoState> {
  final GetProductos getProductos;

  ProductoBloc({required this.getProductos}) : super(ProductoInitial()) {
    on<GetProductosEvent>(_onGetProductos);
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
}
