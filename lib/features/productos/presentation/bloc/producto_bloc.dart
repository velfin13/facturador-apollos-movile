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

  List<Producto> _loadedProductos = [];
  String _currentFiltro = '';
  String? _activoActual = 'S';
  int _currentPage = 0;
  int _total = 0;
  static const int _pageSize = 20;

  ProductoBloc({
    required this.getProductos,
    required this.createProducto,
    required this.updateProducto,
    required this.toggleProductoStatus,
  }) : super(ProductoInitial()) {
    on<GetProductosEvent>(_onGetProductos);
    on<SearchProductosEvent>(_onSearch);
    on<LoadMoreProductosEvent>(_onLoadMore);
    on<CreateProductoEvent>(_onCreateProducto);
    on<UpdateProductoEvent>(_onUpdateProducto);
    on<ToggleProductoStatusEvent>(_onToggleProductoStatus);
  }

  Future<void> _onGetProductos(
    GetProductosEvent event,
    Emitter<ProductoState> emit,
  ) async {
    _activoActual = event.activo;
    _currentFiltro = '';
    _currentPage = 0;
    _loadedProductos = [];
    emit(ProductoLoading());

    final result = await getProductos(GetProductosParams(
      activo: event.activo,
      page: 0,
      size: _pageSize,
    ));
    result.fold(
      (failure) => emit(ProductoError(failure.message)),
      (paged) {
        _loadedProductos = List<Producto>.from(paged.items);
        _total = paged.total;
        emit(ProductoLoaded(
          _loadedProductos,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onSearch(
    SearchProductosEvent event,
    Emitter<ProductoState> emit,
  ) async {
    _currentFiltro = event.filtro;
    _currentPage = 0;
    _loadedProductos = [];
    emit(ProductoLoading());

    final result = await getProductos(GetProductosParams(
      filtro: _currentFiltro.isEmpty ? null : _currentFiltro,
      activo: _activoActual,
      page: 0,
      size: _pageSize,
    ));
    result.fold(
      (failure) => emit(ProductoError(failure.message)),
      (paged) {
        _loadedProductos = List<Producto>.from(paged.items);
        _total = paged.total;
        emit(ProductoLoaded(
          _loadedProductos,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onLoadMore(
    LoadMoreProductosEvent event,
    Emitter<ProductoState> emit,
  ) async {
    final current = state;
    if (current is! ProductoLoaded || !current.hasMore) return;

    _currentPage++;
    final result = await getProductos(GetProductosParams(
      filtro: _currentFiltro.isEmpty ? null : _currentFiltro,
      activo: _activoActual,
      page: _currentPage,
      size: _pageSize,
    ));
    result.fold(
      (failure) => emit(ProductoError(failure.message)),
      (paged) {
        _loadedProductos = [..._loadedProductos, ...paged.items];
        _total = paged.total;
        emit(ProductoLoaded(
          _loadedProductos,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onCreateProducto(
    CreateProductoEvent event,
    Emitter<ProductoState> emit,
  ) async {
    emit(ProductoCreating());
    final result = await createProducto(event.producto);
    result.fold(
      (failure) => emit(ProductoError(failure.message)),
      (producto) {
        emit(ProductoCreated(producto));
        add(GetProductosEvent(activo: _activoActual));
      },
    );
  }

  Future<void> _onUpdateProducto(
    UpdateProductoEvent event,
    Emitter<ProductoState> emit,
  ) async {
    emit(ProductoUpdating());
    final result = await updateProducto(event.producto);
    result.fold(
      (failure) => emit(ProductoError(failure.message)),
      (producto) {
        emit(ProductoUpdated(producto));
        add(GetProductosEvent(activo: _activoActual));
      },
    );
  }

  Future<void> _onToggleProductoStatus(
    ToggleProductoStatusEvent event,
    Emitter<ProductoState> emit,
  ) async {
    final result = await toggleProductoStatus(
      ToggleProductoStatusParams(
        producto: event.producto,
        activar: event.activar,
      ),
    );

    await result.fold(
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
