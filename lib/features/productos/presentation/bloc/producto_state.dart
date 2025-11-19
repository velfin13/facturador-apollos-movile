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

  const ProductoLoaded(this.productos);

  @override
  List<Object> get props => [productos];
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
