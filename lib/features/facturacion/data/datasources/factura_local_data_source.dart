import 'package:injectable/injectable.dart';
import '../models/factura_model.dart';

abstract class FacturaLocalDataSource {
  Future<List<FacturaModel>> getCachedFacturas();
  Future<void> cacheFacturas(List<FacturaModel> facturas);
}

@LazySingleton(as: FacturaLocalDataSource)
class FacturaLocalDataSourceImpl implements FacturaLocalDataSource {
  // Aquí puedes usar SharedPreferences, Hive, SQLite, etc.

  @override
  Future<List<FacturaModel>> getCachedFacturas() async {
    // TODO: Implementar cache local
    throw UnimplementedError();
  }

  @override
  Future<void> cacheFacturas(List<FacturaModel> facturas) async {
    // TODO: Implementar cache local
    throw UnimplementedError();
  }
}
