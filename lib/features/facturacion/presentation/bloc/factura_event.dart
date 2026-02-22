part of 'factura_bloc.dart';

abstract class FacturaEvent extends Equatable {
  const FacturaEvent();

  @override
  List<Object?> get props => [];
}

class GetFacturasEvent extends FacturaEvent {}

class SearchFacturasEvent extends FacturaEvent {
  final String query;

  const SearchFacturasEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterByDateRangeEvent extends FacturaEvent {
  final DateTime? desde;
  final DateTime? hasta;

  const FilterByDateRangeEvent({this.desde, this.hasta});

  @override
  List<Object?> get props => [desde, hasta];
}

class LoadMoreFacturasEvent extends FacturaEvent {}

class GetFacturaDetailsEvent extends FacturaEvent {
  final String id;

  const GetFacturaDetailsEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateFacturaEvent extends FacturaEvent {
  final Factura factura;

  const CreateFacturaEvent(this.factura);

  @override
  List<Object?> get props => [factura];
}
