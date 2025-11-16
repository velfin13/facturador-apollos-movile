part of 'factura_bloc.dart';

abstract class FacturaEvent extends Equatable {
  const FacturaEvent();

  @override
  List<Object> get props => [];
}

class GetFacturasEvent extends FacturaEvent {}
