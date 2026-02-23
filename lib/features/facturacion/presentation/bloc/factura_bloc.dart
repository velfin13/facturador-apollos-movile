import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/factura.dart';
import '../../domain/usecases/get_facturas.dart';
import '../../domain/usecases/get_factura.dart';
import '../../domain/usecases/create_factura.dart';

part 'factura_event.dart';
part 'factura_state.dart';

@injectable
class FacturaBloc extends Bloc<FacturaEvent, FacturaState> {
  final GetFacturas getFacturas;
  final GetFactura getFactura;
  final CreateFactura createFactura;

  List<Factura> _loadedFacturas = [];
  String _currentSearch = '';
  DateTime? _currentFechaDesde;
  DateTime? _currentFechaHasta;
  int _currentPage = 0;
  int _total = 0;
  static const int _pageSize = 20;

  FacturaBloc({
    required this.getFacturas,
    required this.getFactura,
    required this.createFactura,
  }) : super(FacturaInitial()) {
    on<GetFacturasEvent>(_onGetFacturas);
    on<SearchFacturasEvent>(_onSearch);
    on<FilterByDateRangeEvent>(_onFilterByDate);
    on<LoadMoreFacturasEvent>(_onLoadMore);
    on<GetFacturaDetailsEvent>(_onGetFacturaDetails);
    on<CreateFacturaEvent>(_onCreateFactura);
  }

  GetFacturasParams get _currentParams => GetFacturasParams(
        search: _currentSearch.isEmpty ? null : _currentSearch,
        fechaDesde: _currentFechaDesde,
        fechaHasta: _currentFechaHasta,
        page: _currentPage,
        size: _pageSize,
      );

  Future<void> _onGetFacturas(
    GetFacturasEvent event,
    Emitter<FacturaState> emit,
  ) async {
    emit(FacturaLoading());
    _loadedFacturas = [];
    _currentPage = 0;
    _currentSearch = '';
    _currentFechaDesde = null;
    _currentFechaHasta = null;

    final result = await getFacturas(
      const GetFacturasParams(page: 0, size: _pageSize),
    );
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (paged) {
        _loadedFacturas = List<Factura>.from(paged.items);
        _total = paged.total;
        emit(FacturaLoaded(
          _loadedFacturas,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onSearch(
    SearchFacturasEvent event,
    Emitter<FacturaState> emit,
  ) async {
    _currentSearch = event.query;
    _currentPage = 0;
    _loadedFacturas = [];
    emit(FacturaLoading());

    final result = await getFacturas(_currentParams);
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (paged) {
        _loadedFacturas = List<Factura>.from(paged.items);
        _total = paged.total;
        emit(FacturaLoaded(
          _loadedFacturas,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onFilterByDate(
    FilterByDateRangeEvent event,
    Emitter<FacturaState> emit,
  ) async {
    _currentFechaDesde = event.desde;
    _currentFechaHasta = event.hasta;
    _currentPage = 0;
    _loadedFacturas = [];
    emit(FacturaLoading());

    final result = await getFacturas(_currentParams);
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (paged) {
        _loadedFacturas = List<Factura>.from(paged.items);
        _total = paged.total;
        emit(FacturaLoaded(
          _loadedFacturas,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onLoadMore(
    LoadMoreFacturasEvent event,
    Emitter<FacturaState> emit,
  ) async {
    final current = state;
    if (current is! FacturaLoaded || !current.hasMore) return;

    _currentPage++;
    final result = await getFacturas(_currentParams);
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (paged) {
        _loadedFacturas = [..._loadedFacturas, ...paged.items];
        _total = paged.total;
        emit(FacturaLoaded(
          _loadedFacturas,
          hasMore: paged.hasMore,
          total: _total,
        ));
      },
    );
  }

  Future<void> _onGetFacturaDetails(
    GetFacturaDetailsEvent event,
    Emitter<FacturaState> emit,
  ) async {
    final result = await getFactura(event.id);
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (factura) => emit(FacturaDetailsLoaded(factura)),
    );
  }

  Future<void> _onCreateFactura(
    CreateFacturaEvent event,
    Emitter<FacturaState> emit,
  ) async {
    emit(FacturaCreating());
    final result = await createFactura(event.factura);
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (factura) => emit(FacturaCreated(factura)),
    );
  }
}
