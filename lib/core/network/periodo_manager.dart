import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestor del período activo para la API
@lazySingleton
class PeriodoManager {
  static const String _periodoKey = 'periodo_actual';

  final SharedPreferences _prefs;
  String? _periodoActual;

  PeriodoManager(this._prefs) {
    _periodoActual = _prefs.getString(_periodoKey);
  }

  /// Obtiene el período actual
  String get periodoActual {
    if (_periodoActual == null || _periodoActual!.isEmpty) {
      // Por defecto usar el año actual
      _periodoActual = DateTime.now().year.toString();
      setPeriodo(_periodoActual!);
    }
    return _periodoActual!;
  }

  /// Establece un nuevo período
  Future<void> setPeriodo(String periodo) async {
    _periodoActual = periodo;
    await _prefs.setString(_periodoKey, periodo);
  }

  /// Limpia el período
  Future<void> clearPeriodo() async {
    _periodoActual = null;
    await _prefs.remove(_periodoKey);
  }
}
