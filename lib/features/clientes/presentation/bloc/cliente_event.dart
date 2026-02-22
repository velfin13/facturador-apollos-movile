part of 'cliente_bloc.dart';

abstract class ClienteEvent extends Equatable {
  const ClienteEvent();

  @override
  List<Object?> get props => [];
}

class GetClientesEvent extends ClienteEvent {}

class SearchClientesEvent extends ClienteEvent {
  final String query;

  const SearchClientesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterClienteStatusEvent extends ClienteEvent {
  /// '' = todos, 'S' = activos, 'N' = inactivos
  final String activo;

  const FilterClienteStatusEvent(this.activo);

  @override
  List<Object?> get props => [activo];
}

class LoadMoreClientesEvent extends ClienteEvent {}

class CreateClienteEvent extends ClienteEvent {
  final Cliente cliente;

  const CreateClienteEvent(this.cliente);

  @override
  List<Object?> get props => [cliente];
}
