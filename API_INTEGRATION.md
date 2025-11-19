# 🚀 Integración con API - Pasos para completar

## ✅ Lo que ya está hecho

1. **Dependencias agregadas** (pubspec.yaml):
   - dio: Cliente HTTP
   - pretty_dio_logger: Logs de peticiones
   - shared_preferences: Almacenamiento local

2. **Configuración de red**:
   - `api_config.dart`: URLs y configuración
   - `dio_client.dart`: Cliente HTTP configurado
   - `api_exceptions.dart`: Manejo de errores
   - `periodo_manager.dart`: Gestión del período

3. **Data Sources actualizados**:
   - ClienteRemoteDataSource
   - ProductoRemoteDataSource

4. **Modelos y Entidades actualizados** según API

## 📋 Pasos que debes seguir

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Regenerar código
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Verificar la URL de tu API

Edita `lib/core/network/api_config.dart` si tu API NO está en `http://localhost:5117/api`:

```dart
static const String baseUrl = 'TU_URL_AQUI';
```

### 4. Ajustes necesarios

#### a) Actualizar los repositorios

Los repositorios necesitan actualizar sus métodos para manejar los nuevos parámetros. Por ejemplo, en `cliente_repository_impl.dart`:

```dart
@override
Future<Either<Failure, List<Cliente>>> getClientes() async {
  try {
    final clientes = await remoteDataSource.getClientes();  // ← Agregar filtro si necesario
    return Right(clientes);
  } catch (e) {
    if (e is ApiException) {
      return Left(ServerFailure(e.message));
    }
    return Left(ServerFailure(e.toString()));
  }
}
```

#### b) Actualizar los UseCases

Si los use cases necesitan parámetros adicionales (como filtros), actualízalos.

#### c) Actualizar las páginas UI

Las páginas que crean clientes/productos necesitan ajustes porque las entidades cambiaron:

- Agregar el campo `periodo` al crear
- Ajustar los campos que cambiaron (ej: `identificacion` → `ruc`)

### 5. Datos de prueba

Para probar con datos reales, primero crea datos en tu API:

```dart
// Ejemplo de crear un cliente desde la UI
Cliente(
  id: '', // La API debería generarlo
  periodo: '2025', // O usar PeriodoManager
  nombre: 'Cliente de Prueba',
  ruc: '1234567890001',
  activo: true,
  // ... otros campos
)
```

## 🔧 Configuración del Período

El sistema usa un `PeriodoManager` que guarda el período actual. Por defecto usa el año actual (2025).

Para cambiar el período:

```dart
final periodoManager = getIt<PeriodoManager>();
await periodoManager.setPeriodo('2024');
```

## 📱 Ejecutar la app

```bash
# Asegúrate de que tu API esté corriendo en http://localhost:5117
flutter run
```

## 🐛 Solución de problemas

### Error: No se puede conectar a la API
- Verifica que la API esté corriendo
- En Android Emulator usa `http://10.0.2.2:5117/api` en lugar de localhost
- En iOS Simulator usa `http://localhost:5117/api`

### Error: DioClient not found
- Ejecuta `flutter pub run build_runner build --delete-conflicting-outputs`

### Error en modelos
- Los modelos necesitan los archivos `.g.dart` generados
- Ejecuta el build_runner

## 📝 Próximos pasos

1. ✅ Implementar RemoteDataSource para Ventas/Facturas
2. ✅ Crear modelos para FormaPago
3. ✅ Actualizar todas las páginas UI
4. ✅ Implementar manejo de errores en la UI
5. ✅ Agregar indicadores de carga
6. ✅ Implementar retry logic para peticiones fallidas
7. ✅ Agregar cache local para modo offline

## 🔐 Autenticación

Tu API no parece tener endpoints de autenticación. Si la agregas después:

1. Actualizar `AuthRemoteDataSource`
2. Guardar token en SharedPreferences
3. Agregar interceptor en DioClient para incluir token

## 💡 Tip

Usa `pretty_dio_logger` para ver todas las peticiones HTTP en la consola mientras desarrollas. Esto te ayudará a debuggear.

---

**Nota**: Algunos archivos pueden necesitar ajustes adicionales según las respuestas exactas de tu API. Revisa los logs para identificar problemas de mapeo.
