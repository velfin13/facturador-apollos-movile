import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestor del período activo para la API
@lazySingleton
class PeriodoManager {
  static const String _periodoKey = 'periodo_actual';
  static const String _defaultPeriodo = '1';

  final SharedPreferences _prefs;
  String? _periodoActual;

  PeriodoManager(this._prefs) {
    _periodoActual = _prefs.getString(_periodoKey);

    // Migracion de valor legado: antes se guardaba el anio actual (ej. 2026).
    // En este proyecto IdSysPeriodo no es anio, sino identificador de empresa/periodo.
    if (_periodoActual != null &&
        RegExp(r'^20\d{2}$').hasMatch(_periodoActual!)) {
      _periodoActual = _defaultPeriodo;
      _prefs.setString(_periodoKey, _defaultPeriodo);
    }
  }

  /// Obtiene el período actual
  String get periodoActual {
    // Defensa extra: si por cualquier motivo queda guardado un anio (ej. 2026),
    // lo corregimos en caliente al periodo por defecto de la empresa.
    if (_periodoActual != null &&
        RegExp(r'^20\d{2}$').hasMatch(_periodoActual!)) {
      _periodoActual = _defaultPeriodo;
      _prefs.setString(_periodoKey, _defaultPeriodo);
    }

    if (_periodoActual == null || _periodoActual!.isEmpty) {
      // En este backend IdSysPeriodo representa el contexto de empresa/periodo, no el año calendario.
      _periodoActual = _defaultPeriodo;
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
