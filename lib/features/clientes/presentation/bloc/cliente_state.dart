part of 'cliente_bloc.dart';

abstract class ClienteState extends Equatable {
  const ClienteState();

  @override
  List<Object?> get props => [];
}

class ClienteInitial extends ClienteState {}

class ClienteLoading extends ClienteState {}

class ClienteLoaded extends ClienteState {
  final List<Cliente> clientes;
  final bool hasMore;
  final int total;

  const ClienteLoaded(this.clientes, {this.hasMore = false, this.total = 0});

  @override
  List<Object?> get props => [clientes, hasMore, total];
}

class ClienteError extends ClienteState {
  final String message;

  const ClienteError(this.message);

  @override
  List<Object?> get props => [message];
}

class ClienteCreating extends ClienteState {}

class ClienteCreated extends ClienteState {
  final Cliente cliente;

  const ClienteCreated(this.cliente);

  @override
  List<Object?> get props => [cliente];
}

class ClienteUpdating extends ClienteState {}

class ClienteUpdated extends ClienteState {
  final Cliente cliente;

  const ClienteUpdated(this.cliente);

  @override
  List<Object?> get props => [cliente];
}
