import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
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

  List<Factura> _allFacturas = [];
  String _searchQuery = '';
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  int _page = 0;
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

  List<Factura> get _filtered {
    var list = _allFacturas;
    if (_fechaDesde != null) {
      final desde = DateTime(_fechaDesde!.year, _fechaDesde!.month, _fechaDesde!.day);
      list = list.where((f) => !f.fecha.isBefore(desde)).toList();
    }
    if (_fechaHasta != null) {
      final hasta = DateTime(_fechaHasta!.year, _fechaHasta!.month, _fechaHasta!.day, 23, 59, 59);
      list = list.where((f) => !f.fecha.isAfter(hasta)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((f) =>
        (f.numFact ?? '').toLowerCase().contains(q) ||
        (f.clienteNombre ?? '').toLowerCase().contains(q) ||
        f.total.toStringAsFixed(2).contains(q),
      ).toList();
    }
    return list;
  }

  FacturaLoaded _buildPagedState() {
    final filtered = _filtered;
    final end = ((_page + 1) * _pageSize).clamp(0, filtered.length);
    return FacturaLoaded(
      filtered.sublist(0, end),
      hasMore: end < filtered.length,
      total: filtered.length,
    );
  }

  Future<void> _onGetFacturas(GetFacturasEvent event, Emitter<FacturaState> emit) async {
    emit(FacturaLoading());
    _page = 0;
    final result = await getFacturas(NoParams());
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (facturas) {
        _allFacturas = facturas;
        emit(_buildPagedState());
      },
    );
  }

  void _onSearch(SearchFacturasEvent event, Emitter<FacturaState> emit) {
    _searchQuery = event.query;
    _page = 0;
    emit(_buildPagedState());
  }

  void _onFilterByDate(FilterByDateRangeEvent event, Emitter<FacturaState> emit) {
    _fechaDesde = event.desde;
    _fechaHasta = event.hasta;
    _page = 0;
    emit(_buildPagedState());
  }

  void _onLoadMore(LoadMoreFacturasEvent event, Emitter<FacturaState> emit) {
    final current = state;
    if (current is FacturaLoaded && current.hasMore) {
      _page++;
      emit(_buildPagedState());
    }
  }

  Future<void> _onGetFacturaDetails(GetFacturaDetailsEvent event, Emitter<FacturaState> emit) async {
    final result = await getFactura(event.id);
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (factura) => emit(FacturaDetailsLoaded(factura)),
    );
  }

  Future<void> _onCreateFactura(CreateFacturaEvent event, Emitter<FacturaState> emit) async {
    emit(FacturaCreating());
    final result = await createFactura(event.factura);
    result.fold(
      (failure) => emit(FacturaError(failure.message)),
      (factura) => emit(FacturaCreated(factura)),
    );
  }
}
