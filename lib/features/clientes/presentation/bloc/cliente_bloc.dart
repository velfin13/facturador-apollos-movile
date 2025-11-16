import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/get_clientes.dart';

part 'cliente_event.dart';
part 'cliente_state.dart';

@injectable
class ClienteBloc extends Bloc<ClienteEvent, ClienteState> {
  final GetClientes getClientes;

  ClienteBloc({required this.getClientes}) : super(ClienteInitial()) {
    on<GetClientesEvent>(_onGetClientes);
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
}
