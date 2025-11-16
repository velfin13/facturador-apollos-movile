import 'package:injectable/injectable.dart';
import '../models/factura_model.dart';

abstract class FacturaRemoteDataSource {
  Future<List<FacturaModel>> getFacturas();
  Future<FacturaModel> getFactura(String id);
  Future<FacturaModel> createFactura(FacturaModel factura);
  Future<void> deleteFactura(String id);
}

@LazySingleton(as: FacturaRemoteDataSource)
class FacturaRemoteDataSourceImpl implements FacturaRemoteDataSource {
  // Aquí usarías http, dio, o tu cliente API preferido

  @override
  Future<List<FacturaModel>> getFacturas() async {
    // TODO: Implementar llamada API
    // Por ahora devolvemos datos mock
    await Future.delayed(const Duration(seconds: 1));
    return [
      FacturaModel(
        id: '1',
        clienteNombre: 'Juan Pérez',
        total: 150.50,
        fecha: DateTime.now(),
        itemsModel: const [
          ItemFacturaModel(
            descripcion: 'Producto A',
            cantidad: 2,
            precioUnitario: 50.25,
          ),
          ItemFacturaModel(
            descripcion: 'Producto B',
            cantidad: 1,
            precioUnitario: 50.00,
          ),
        ],
      ),
    ];
  }

  @override
  Future<FacturaModel> getFactura(String id) async {
    // TODO: Implementar llamada API
    throw UnimplementedError();
  }

  @override
  Future<FacturaModel> createFactura(FacturaModel factura) async {
    // TODO: Implementar llamada API
    throw UnimplementedError();
  }

  @override
  Future<void> deleteFactura(String id) async {
    // TODO: Implementar llamada API
    throw UnimplementedError();
  }
}
