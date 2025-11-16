part of 'cliente_bloc.dart';

abstract class ClienteEvent extends Equatable {
  const ClienteEvent();

  @override
  List<Object> get props => [];
}

class GetClientesEvent extends ClienteEvent {}

class CreateClienteEvent extends ClienteEvent {
  final Cliente cliente;

  const CreateClienteEvent(this.cliente);

  @override
  List<Object> get props => [cliente];
}
