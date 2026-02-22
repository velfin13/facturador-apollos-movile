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

  List<Cliente> _allClientes = [];
  String _searchQuery = '';
  String _filtroActivo = ''; // '' todos, 'S' activos, 'N' inactivos
  int _page = 0;
  static const int _pageSize = 20;

  ClienteBloc({required this.getClientes, required this.createCliente})
      : super(ClienteInitial()) {
    on<GetClientesEvent>(_onGetClientes);
    on<SearchClientesEvent>(_onSearch);
    on<FilterClienteStatusEvent>(_onFilterStatus);
    on<LoadMoreClientesEvent>(_onLoadMore);
    on<CreateClienteEvent>(_onCreateCliente);
  }

  List<Cliente> get _filtered {
    var list = _allClientes;
    if (_filtroActivo == 'S') {
      list = list.where((c) => c.activo).toList();
    } else if (_filtroActivo == 'N') {
      list = list.where((c) => !c.activo).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
        c.nombre.toLowerCase().contains(q) ||
        c.ruc.toLowerCase().contains(q) ||
        (c.email ?? '').toLowerCase().contains(q) ||
        (c.ciudad ?? '').toLowerCase().contains(q),
      ).toList();
    }
    return list;
  }

  ClienteLoaded _buildPagedState() {
    final filtered = _filtered;
    final end = ((_page + 1) * _pageSize).clamp(0, filtered.length);
    return ClienteLoaded(
      filtered.sublist(0, end),
      hasMore: end < filtered.length,
      total: filtered.length,
    );
  }

  Future<void> _onGetClientes(GetClientesEvent event, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    _page = 0;
    final result = await getClientes(NoParams());
    result.fold(
      (failure) => emit(ClienteError(failure.message)),
      (clientes) {
        _allClientes = clientes;
        emit(_buildPagedState());
      },
    );
  }

  void _onSearch(SearchClientesEvent event, Emitter<ClienteState> emit) {
    _searchQuery = event.query;
    _page = 0;
    emit(_buildPagedState());
  }

  void _onFilterStatus(FilterClienteStatusEvent event, Emitter<ClienteState> emit) {
    _filtroActivo = event.activo;
    _page = 0;
    emit(_buildPagedState());
  }

  void _onLoadMore(LoadMoreClientesEvent event, Emitter<ClienteState> emit) {
    final current = state;
    if (current is ClienteLoaded && current.hasMore) {
      _page++;
      emit(_buildPagedState());
    }
  }

  Future<void> _onCreateCliente(CreateClienteEvent event, Emitter<ClienteState> emit) async {
    emit(ClienteCreating());
    final result = await createCliente(CreateClienteParams(cliente: event.cliente));
    result.fold(
      (failure) => emit(ClienteError(failure.message)),
      (cliente) => emit(ClienteCreated(cliente)),
    );
  }
}
