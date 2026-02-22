import 'package:flutter/material.dart';

/// Tema central de la aplicación.
/// Para cambiar la paleta de colores, solo edita los valores de [brand] y
/// [brandDark] — el resto del sistema de colores se genera automáticamente.
class AppTheme {
  // ── Colores de marca ─────────────────────────────────────────────────────
  /// Color primario de la marca. Cambia este valor para recoloreaar la app.
  static const Color brand = Color(0xFF1565C0); // azul corporativo

  /// Usado en gradientes y variantes oscuras del color de marca.
  static const Color brandDark = Color(0xFF0D47A1);

  // ── Colores semánticos ───────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color danger  = Color(0xFFC62828);
  static const Color info    = Color(0xFF0277BD);

  // ── Tema claro ───────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    ),
    // AppBar sin sombra ni color especial — usa el color de surface del scheme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    // Cards con bordes redondeados consistentes
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    // Botones rellenos con bordes redondeados
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    // Inputs con borde redondeado
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    // FAB sin sombra excesiva
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
    ),
  );
}
