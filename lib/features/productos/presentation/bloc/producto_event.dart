part of 'producto_bloc.dart';

abstract class ProductoEvent extends Equatable {
  const ProductoEvent();

  @override
  List<Object?> get props => [];
}

class GetProductosEvent extends ProductoEvent {
  final String? activo; // 'S', 'N' o null (todos)

  const GetProductosEvent({this.activo = 'S'});

  @override
  List<Object?> get props => [activo];
}

class SearchProductosEvent extends ProductoEvent {
  final String filtro;

  const SearchProductosEvent(this.filtro);

  @override
  List<Object?> get props => [filtro];
}

class LoadMoreProductosEvent extends ProductoEvent {}

class CreateProductoEvent extends ProductoEvent {
  final Producto producto;

  const CreateProductoEvent(this.producto);

  @override
  List<Object> get props => [producto];
}

class UpdateProductoEvent extends ProductoEvent {
  final Producto producto;

  const UpdateProductoEvent(this.producto);

  @override
  List<Object> get props => [producto];
}

class ToggleProductoStatusEvent extends ProductoEvent {
  final Producto producto;
  final bool activar;

  const ToggleProductoStatusEvent({
    required this.producto,
    required this.activar,
  });

  @override
  List<Object> get props => [producto, activar];
}
