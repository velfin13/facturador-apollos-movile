import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/get_clientes.dart';
import '../../domain/usecases/create_cliente.dart';
import '../../domain/usecases/update_cliente.dart';

part 'cliente_event.dart';
part 'cliente_state.dart';

@injectable
class ClienteBloc extends Bloc<ClienteEvent, ClienteState> {
  final GetClientes getClientes;
  final CreateCliente createCliente;
  final UpdateCliente updateCliente;

  List<Cliente> _loadedClientes = [];
  String _currentSearch = '';
  int _currentPage = 0;
  int _total = 0;
  static const int _pageSize = 20;

  ClienteBloc({
    required this.getClientes,
    required this.createCliente,
    required this.updateCliente,
  }) : super(ClienteInitial()) {
    on<GetClientesEvent>(_onGetClientes);
    on<SearchClientesEvent>(_onSearch);
    on<FilterClienteStatusEvent>(_onFilterStatus);
    on<LoadMoreClientesEvent>(_onLoadMore);
    on<CreateClienteEvent>(_onCreateCliente);
    on<UpdateClienteEvent>(_onUpdateCliente);
  }

  Future<void> _onGetClientes(
    GetClientesEvent event,
    Emitter<ClienteState> emit,
  ) async {
    emit(ClienteLoading());
    _loadedClientes = [];
    _currentPage = 0;
    _currentSearch = '';

    final result = await getClientes(
      const GetClientesParams(page: 0, size: _pageSize),
    );
    result.fold(
      (failure) => emit(ClienteError(failure.message)),
      (paged) {
        _loadedClientes = List<Cliente>.from(paged.items);
        _total = paged.total;
        emit(ClienteLoaded(
          _loadedClientes,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onSearch(
    SearchClientesEvent event,
    Emitter<ClienteState> emit,
  ) async {
    _currentSearch = event.query;
    _currentPage = 0;
    _loadedClientes = [];
    emit(ClienteLoading());

    final result = await getClientes(GetClientesParams(
      search: _currentSearch.isEmpty ? null : _currentSearch,
      page: 0,
      size: _pageSize,
    ));
    result.fold(
      (failure) => emit(ClienteError(failure.message)),
      (paged) {
        _loadedClientes = List<Cliente>.from(paged.items);
        _total = paged.total;
        emit(ClienteLoaded(
          _loadedClientes,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  void _onFilterStatus(
    FilterClienteStatusEvent event,
    Emitter<ClienteState> emit,
  ) {
    // Filtro visual sobre los elementos ya cargados (el SP devuelve solo activos).
    final current = state;
    if (current is ClienteLoaded) {
      final filtered = event.activo.isEmpty
          ? _loadedClientes
          : _loadedClientes
              .where(
                (c) => event.activo == 'S' ? c.activo : !c.activo,
              )
              .toList();
      emit(ClienteLoaded(
        filtered,
        hasMore: current.hasMore,
        total: current.total,
      ));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreClientesEvent event,
    Emitter<ClienteState> emit,
  ) async {
    final current = state;
    if (current is! ClienteLoaded || !current.hasMore) return;

    _currentPage++;
    final result = await getClientes(GetClientesParams(
      search: _currentSearch.isEmpty ? null : _currentSearch,
      page: _currentPage,
      size: _pageSize,
    ));
    result.fold(
      (failure) => emit(ClienteError(failure.message)),
      (paged) {
        _loadedClientes = [..._loadedClientes, ...paged.items];
        _total = paged.total;
        emit(ClienteLoaded(
          _loadedClientes,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onCreateCliente(
    CreateClienteEvent event,
    Emitter<ClienteState> emit,
  ) async {
    emit(ClienteCreating());
    final result = await createCliente(
      CreateClienteParams(cliente: event.cliente),
    );
    result.fold(
      (failure) => emit(ClienteError(failure.message)),
      (cliente) => emit(ClienteCreated(cliente)),
    );
  }

  Future<void> _onUpdateCliente(
    UpdateClienteEvent event,
    Emitter<ClienteState> emit,
  ) async {
    emit(ClienteUpdating());
    final result = await updateCliente(
      UpdateClienteParams(cliente: event.cliente),
    );
    result.fold(
      (failure) => emit(ClienteError(failure.message)),
      (updatedCliente) {
        final idx = _loadedClientes.indexWhere((c) => c.id == updatedCliente.id);
        if (idx != -1) {
          final updated = List<Cliente>.from(_loadedClientes);
          updated[idx] = updatedCliente;
          _loadedClientes = updated;
        }
        emit(ClienteUpdated(updatedCliente));
        emit(ClienteLoaded(
          _loadedClientes,
          hasMore: (_currentPage + 1) * _pageSize < _total,
          total: _total,
        ));
      },
    );
  }
}
