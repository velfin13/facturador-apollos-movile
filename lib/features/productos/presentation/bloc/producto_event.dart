part of 'producto_bloc.dart';

abstract class ProductoEvent extends Equatable {
  const ProductoEvent();

  @override
  List<Object> get props => [];
}

class GetProductosEvent extends ProductoEvent {}

class CreateProductoEvent extends ProductoEvent {
  final Producto producto;

  const CreateProductoEvent(this.producto);

  @override
  List<Object> get props => [producto];
}
