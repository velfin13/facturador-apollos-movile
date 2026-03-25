part of 'factura_bloc.dart';

abstract class FacturaState extends Equatable {
  const FacturaState();

  @override
  List<Object?> get props => [];
}

class FacturaInitial extends FacturaState {}

class FacturaLoading extends FacturaState {}

class FacturaLoaded extends FacturaState {
  final List<Factura> facturas;
  final bool hasMore;
  final int total;

  const FacturaLoaded(this.facturas, {this.hasMore = false, this.total = 0});

  @override
  List<Object?> get props => [facturas, hasMore, total];
}

class FacturaDetailsLoaded extends FacturaState {
  final Factura factura;

  const FacturaDetailsLoaded(this.factura);

  @override
  List<Object?> get props => [factura];
}

class FacturaError extends FacturaState {
  final String message;

  const FacturaError(this.message);

  @override
  List<Object?> get props => [message];
}

class FacturaCreating extends FacturaState {}

class FacturaCreated extends FacturaState {
  final Factura factura;

  const FacturaCreated(this.factura);

  @override
  List<Object?> get props => [factura];
}

class AutorizacionVerificada extends FacturaState {
  final int idSysFcCabVenta;
  final String estado;

  const AutorizacionVerificada({required this.idSysFcCabVenta, required this.estado});

  @override
  List<Object?> get props => [idSysFcCabVenta, estado];
}

class NotaCreditoCreating extends FacturaState {}

class NotaCreditoCreated extends FacturaState {
  final Factura notaCredito;

  const NotaCreditoCreated(this.notaCredito);

  @override
  List<Object?> get props => [notaCredito];
}
