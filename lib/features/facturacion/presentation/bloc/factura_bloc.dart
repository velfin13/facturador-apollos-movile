import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/factura.dart';
import '../../domain/usecases/get_facturas.dart';

part 'factura_event.dart';
part 'factura_state.dart';

@injectable
class FacturaBloc extends Bloc<FacturaEvent, FacturaState> {
  final GetFacturas getFacturas;

  FacturaBloc({required this.getFacturas}) : super(FacturaInitial()) {
    on<GetFacturasEvent>(_onGetFacturas);
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
}
