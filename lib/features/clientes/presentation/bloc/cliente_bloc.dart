import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/get_clientes.dart';
import '../../domain/usecases/create_cliente.dart';

part 'cliente_event.dart';
part 'cliente_state.dart';

@injectable
class ClienteBloc extends Bloc<ClienteEvent, ClienteState> {
  final GetClientes getClientes;
  final CreateCliente createCliente;

  ClienteBloc({required this.getClientes, required this.createCliente})
    : super(ClienteInitial()) {
    on<GetClientesEvent>(_onGetClientes);
    on<CreateClienteEvent>(_onCreateCliente);
  }

  Future<void> _onGetClientes(
    GetClientesEvent event,
    Emitter<ClienteState> emit,
  ) async {
    emit(ClienteLoading());

    final failureOrClientes = await getClientes(NoParams());

    failureOrClientes.fold(
      (failure) => emit(ClienteError(failure.message)),
      (clientes) => emit(ClienteLoaded(clientes)),
    );
  }

  Future<void> _onCreateCliente(
    CreateClienteEvent event,
    Emitter<ClienteState> emit,
  ) async {
    emit(ClienteCreating());

    final failureOrCliente = await createCliente(
      CreateClienteParams(cliente: event.cliente),
    );

    failureOrCliente.fold(
      (failure) => emit(ClienteError(failure.message)),
      (cliente) => emit(ClienteCreated(cliente)),
    );
  }
}
