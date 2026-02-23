part of 'producto_bloc.dart';

abstract class ProductoState extends Equatable {
  const ProductoState();

  @override
  List<Object> get props => [];
}

class ProductoInitial extends ProductoState {}

class ProductoLoading extends ProductoState {}

class ProductoLoaded extends ProductoState {
  final List<Producto> productos;
  final bool hasMore;
  final int total;

  const ProductoLoaded(
    this.productos, {
    this.hasMore = false,
    this.total = 0,
  });

  @override
  List<Object> get props => [productos, hasMore, total];
}

class ProductoError extends ProductoState {
  final String message;

  const ProductoError(this.message);

  @override
  List<Object> get props => [message];
}

class ProductoCreating extends ProductoState {}

class ProductoCreated extends ProductoState {
  final Producto producto;

  const ProductoCreated(this.producto);

  @override
  List<Object> get props => [producto];
}

class ProductoUpdating extends ProductoState {}

class ProductoUpdated extends ProductoState {
  final Producto producto;

  const ProductoUpdated(this.producto);

  @override
  List<Object> get props => [producto];
}

class ProductoStatusUpdated extends ProductoState {
  final String message;

  const ProductoStatusUpdated(this.message);

  @override
  List<Object> get props => [message];
}
