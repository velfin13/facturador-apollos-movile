part of 'factura_bloc.dart';

abstract class FacturaState extends Equatable {
  const FacturaState();

  @override
  List<Object> get props => [];
}

class FacturaInitial extends FacturaState {}

class FacturaLoading extends FacturaState {}

class FacturaLoaded extends FacturaState {
  final List<Factura> facturas;

  const FacturaLoaded(this.facturas);

  @override
  List<Object> get props => [facturas];
}

class FacturaError extends FacturaState {
  final String message;

  const FacturaError(this.message);

  @override
  List<Object> get props => [message];
}
