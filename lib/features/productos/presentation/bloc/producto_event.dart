part of 'producto_bloc.dart';

abstract class ProductoEvent extends Equatable {
  const ProductoEvent();

  @override
  List<Object> get props => [];
}

class GetProductosEvent extends ProductoEvent {}
