import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/factura.dart';
import '../../domain/usecases/get_facturas.dart';
import '../../domain/usecases/create_factura.dart';

part 'factura_event.dart';
part 'factura_state.dart';

@injectable
class FacturaBloc extends Bloc<FacturaEvent, FacturaState> {
  final GetFacturas getFacturas;
  final CreateFactura createFactura;

  FacturaBloc({required this.getFacturas, required this.createFactura})
    : super(FacturaInitial()) {
    on<GetFacturasEvent>(_onGetFacturas);
    on<CreateFacturaEvent>(_onCreateFactura);
  }

  Future<void> _onGetFacturas(
    GetFacturasEvent event,
    Emitter<FacturaState> emit,
  ) async {
    emit(FacturaLoading());

    final failureOrFacturas = await getFacturas(NoParams());

    failureOrFacturas.fold(
      (failure) => emit(FacturaError(failure.message)),
      (facturas) => emit(FacturaLoaded(facturas)),
    );
  }

  Future<void> _onCreateFactura(
    CreateFacturaEvent event,
    Emitter<FacturaState> emit,
  ) async {
    emit(FacturaCreating());

    final failureOrFactura = await createFactura(event.factura);

    failureOrFactura.fold(
      (failure) => emit(FacturaError(failure.message)),
      (factura) => emit(FacturaCreated(factura)),
    );
  }
}
