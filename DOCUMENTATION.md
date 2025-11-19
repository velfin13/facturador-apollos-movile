# 📱 Facturador - Sistema de Facturación Móvil

## 📋 Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Arquitectura del Proyecto](#arquitectura-del-proyecto)
- [Stack Tecnológico](#stack-tecnológico)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Módulos y Características](#módulos-y-características)
- [Entidades del Dominio](#entidades-del-dominio)
- [Gestión de Estado](#gestión-de-estado)
- [Inyección de Dependencias](#inyección-de-dependencias)
- [Guía de Inicio](#guía-de-inicio)
- [Roadmap y TODOs](#roadmap-y-todos)

---

## 📖 Descripción General

**Facturador** es una aplicación móvil desarrollada en Flutter para la gestión completa de facturación electrónica. El sistema permite la administración de clientes, productos y generación de facturas con un sistema de roles diferenciados (Administrador, Vendedor, Contador).

### Características Principales

- ✅ Sistema de autenticación con roles
- ✅ Gestión completa de clientes (CRUD)
- ✅ Catálogo de productos con control de inventario
- ✅ Generación de facturas con múltiples items
- ✅ Visualización de historial de facturas
- ✅ Arquitectura limpia y escalable
- ✅ Manejo robusto de errores
- 🚧 Integración con API backend (pendiente)
- 🚧 Sincronización offline (pendiente)
- 🚧 Reportes y estadísticas (pendiente)

---

## 🏗️ Arquitectura del Proyecto

El proyecto implementa **Clean Architecture** (Arquitectura Limpia) con tres capas claramente separadas:

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  (UI, BLoC, Widgets, Pages)            │
├─────────────────────────────────────────┤
│         DOMAIN LAYER                    │
│  (Entities, UseCases, Repositories)    │
├─────────────────────────────────────────┤
│         DATA LAYER                      │
│  (Models, DataSources, Repositories)   │
└─────────────────────────────────────────┘
```

### Principios Aplicados

- **Separación de Responsabilidades**: Cada capa tiene un propósito específico
- **Inversión de Dependencias**: Las capas internas no conocen las externas
- **Single Responsibility**: Cada clase tiene una única responsabilidad
- **Dependency Injection**: Desacoplamiento mediante inyección de dependencias
- **Test Driven**: Estructura preparada para testing

---

## 🛠️ Stack Tecnológico

### Framework y Lenguaje

- **Flutter**: ^3.10.0
- **Dart**: ^3.10.0

### Gestión de Estado

- **flutter_bloc**: ^9.1.1 - Implementación del patrón BLoC
- **equatable**: ^2.0.7 - Comparación de objetos simplificada

### Programación Funcional

- **dartz**: ^0.10.1 - Either para manejo de errores funcional

### Inyección de Dependencias

- **get_it**: ^9.0.5 - Service Locator
- **injectable**: ^2.6.0 - Generación automática de código DI

### Serialización

- **json_annotation**: ^4.9.0
- **json_serializable**: ^6.11.1
- **freezed**: ^3.2.3
- **freezed_annotation**: ^3.1.0

### Utilidades

- **intl**: ^0.20.2 - Internacionalización y formateo de fechas

### Herramientas de Desarrollo

- **build_runner**: ^2.10.3
- **injectable_generator**: ^2.9.1
- **flutter_lints**: ^6.0.0

---

## 📁 Estructura del Proyecto

```
facturador/
├── lib/
│   ├── main.dart                          # Punto de entrada
│   │
│   ├── core/                              # Funcionalidad compartida
│   │   ├── error/
│   │   │   └── failures.dart              # Clases de errores
│   │   ├── network/                       # (Futuro) Cliente HTTP
│   │   └── usecases/
│   │       └── usecase.dart               # Clase base para casos de uso
│   │
│   ├── injection/                         # Configuración DI
│   │   ├── injection_container.dart       # Setup de inyección
│   │   └── injection_container.config.dart # Auto-generado
│   │
│   └── features/                          # Módulos por característica
│       │
│       ├── auth/                          # Módulo de Autenticación
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── auth_local_data_source.dart
│       │   │   ├── models/
│       │   │   │   └── usuario_model.dart
│       │   │   └── repositories/
│       │   │       └── auth_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── usuario.dart
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository.dart
│       │   │   └── usecases/
│       │   │       ├── login.dart
│       │   │       └── logout.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── auth_bloc.dart
│       │       │   ├── auth_event.dart
│       │       │   └── auth_state.dart
│       │       └── pages/
│       │           ├── login_page.dart
│       │           └── home_page.dart
│       │
│       ├── clientes/                      # Módulo de Clientes
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── cliente_local_data_source.dart
│       │   │   │   └── cliente_remote_data_source.dart
│       │   │   ├── models/
│       │   │   │   └── cliente_model.dart
│       │   │   └── repositories/
│       │   │       └── cliente_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── cliente.dart
│       │   │   ├── repositories/
│       │   │   │   └── cliente_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_cliente.dart
│       │   │       ├── delete_cliente.dart
│       │   │       ├── get_cliente.dart
│       │   │       ├── get_clientes.dart
│       │   │       └── update_cliente.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── cliente_bloc.dart
│       │       │   ├── cliente_event.dart
│       │       │   └── cliente_state.dart
│       │       ├── pages/
│       │       │   ├── clientes_page.dart
│       │       │   └── crear_cliente_page.dart
│       │       └── widgets/
│       │           └── cliente_list_widget.dart
│       │
│       ├── productos/                     # Módulo de Productos
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── producto_local_data_source.dart
│       │   │   │   └── producto_remote_data_source.dart
│       │   │   ├── models/
│       │   │   │   └── producto_model.dart
│       │   │   └── repositories/
│       │   │       └── producto_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── producto.dart
│       │   │   ├── repositories/
│       │   │   │   └── producto_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_producto.dart
│       │   │       ├── delete_producto.dart
│       │   │       ├── get_producto.dart
│       │   │       ├── get_productos.dart
│       │   │       └── update_producto.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── producto_bloc.dart
│       │       │   ├── producto_event.dart
│       │       │   └── producto_state.dart
│       │       ├── pages/
│       │       │   └── productos_page.dart
│       │       └── widgets/
│       │           └── producto_list_widget.dart
│       │
│       └── facturacion/                   # Módulo de Facturación
│           ├── data/
│           │   ├── datasources/
│           │   │   ├── factura_local_data_source.dart
│           │   │   └── factura_remote_data_source.dart
│           │   ├── models/
│           │   │   ├── factura_model.dart
│           │   │   └── factura_model.g.dart
│           │   └── repositories/
│           │       └── factura_repository_impl.dart
│           ├── domain/
│           │   ├── entities/
│           │   │   └── factura.dart
│           │   ├── repositories/
│           │   │   └── factura_repository.dart
│           │   └── usecases/
│           │       ├── create_factura.dart
│           │       ├── delete_factura.dart
│           │       ├── get_factura.dart
│           │       └── get_facturas.dart
│           └── presentation/
│               ├── bloc/
│               │   ├── factura_bloc.dart
│               │   ├── factura_event.dart
│               │   └── factura_state.dart
│               ├── pages/
│               │   ├── crear_factura_page.dart
│               │   └── facturas_page.dart
│               └── widgets/
│                   └── factura_list_widget.dart
│
├── test/                                  # Tests unitarios
├── android/                               # Configuración Android
├── ios/                                   # Configuración iOS
├── web/                                   # Configuración Web
├── linux/                                 # Configuración Linux
├── macos/                                 # Configuración macOS
├── windows/                               # Configuración Windows
│
├── pubspec.yaml                           # Dependencias del proyecto
├── analysis_options.yaml                  # Reglas de linting
└── README.md                              # README básico
```

---

## 🎯 Módulos y Características

### 1. Módulo de Autenticación (`auth`)

**Propósito**: Gestionar la autenticación y autorización de usuarios.

#### Características

- Login con email y contraseña
- Sistema de roles (Admin, Vendedor, Contador)
- Persistencia de sesión (simulada)
- Logout

#### Usuarios de Prueba

| Email                        | Rol          | Permisos                              |
|------------------------------|--------------|---------------------------------------|
| admin@facturador.com         | Administrador| Acceso completo                       |
| vendedor@facturador.com      | Vendedor     | Crear facturas, ver clientes          |
| contador@facturador.com      | Contador     | Ver facturas, reportes                |

**Contraseña para todos**: `password123`

#### Estados del BLoC

```dart
- AuthInitial: Estado inicial
- AuthLoading: Autenticando usuario
- AuthAuthenticated: Usuario autenticado
- AuthUnauthenticated: Sin sesión activa
- AuthError: Error en autenticación
```

#### Eventos del BLoC

```dart
- LoginEvent: Intenta login
- LogoutEvent: Cierra sesión
- CheckAuthEvent: Verifica sesión existente
```

---

### 2. Módulo de Clientes (`clientes`)

**Propósito**: Gestión completa del catálogo de clientes.

#### Características

- ✅ Listar todos los clientes
- ✅ Crear nuevo cliente
- ✅ Ver detalles de cliente
- ✅ Actualizar información (parcial)
- ✅ Eliminar cliente (soft delete)
- ✅ Búsqueda y filtros (UI básica)

#### Entidad Cliente

```dart
class Cliente {
  final String id;
  final String nombre;
  final String? razonSocial;
  final String identificacion;  // RUC, CI, Pasaporte
  final String? email;
  final String? telefono;
  final String? direccion;
  final bool activo;
  final DateTime fechaCreacion;
}
```

#### Estados del BLoC

```dart
- ClienteInitial
- ClienteLoading
- ClienteLoaded(List<Cliente>)
- ClienteError(String message)
- ClienteCreating
- ClienteCreated(Cliente)
```

#### Data Sources

- **Remote**: Datos mock en memoria (preparado para API)
- **Local**: Cache local (pendiente de implementación)

---

### 3. Módulo de Productos (`productos`)

**Propósito**: Administración del inventario de productos y servicios.

#### Características

- ✅ Catálogo de productos con stock
- ✅ Crear producto con código único
- ✅ Actualizar precios y stock
- ✅ Eliminar productos
- ✅ Categorización
- ✅ Cálculo de margen de ganancia

#### Entidad Producto

```dart
class Producto {
  final String id;
  final String codigo;           // Código único del producto
  final String nombre;
  final String? descripcion;
  final double precio;           // Precio de venta
  final double? costo;           // Costo de adquisición
  final int stock;               // Cantidad disponible
  final String? categoria;
  final bool activo;
  final DateTime fechaCreacion;
  
  // Getters calculados
  double get margen;             // Porcentaje de ganancia
  bool get disponible;           // activo && stock > 0
}
```

#### Funcionalidades Especiales

- **Control de Stock**: Validación de disponibilidad
- **Cálculo de Margen**: `((precio - costo) / costo) * 100`
- **Categorías**: Organización por tipo de producto

---

### 4. Módulo de Facturación (`facturacion`)

**Propósito**: Creación y gestión de facturas electrónicas.

#### Características

- ✅ Crear factura con múltiples items
- ✅ Selección de cliente desde catálogo
- ✅ Agregar productos desde inventario
- ✅ Cálculo automático de totales
- ✅ Historial de facturas
- ✅ Ver detalle de factura
- 🚧 Exportar PDF
- 🚧 Envío por email
- 🚧 Integración con SRI (Ecuador)

#### Entidades

**Factura**
```dart
class Factura {
  final String id;
  final String clienteNombre;
  final double total;
  final DateTime fecha;
  final List<ItemFactura> items;
}
```

**ItemFactura**
```dart
class ItemFactura {
  final String descripcion;
  final int cantidad;
  final double precioUnitario;
  
  double get subtotal => cantidad * precioUnitario;
}
```

#### Flujo de Creación

1. **Seleccionar Cliente**: Dropdown con catálogo completo
2. **Agregar Items**: 
   - Seleccionar producto del inventario
   - Especificar cantidad
   - Ajustar precio si es necesario
3. **Cálculo Automático**: 
   - Subtotal por item
   - Total general
   - (Futuro) IVA y descuentos
4. **Guardar Factura**: Persistencia y generación de ID

#### Estados del BLoC

```dart
- FacturaInitial
- FacturaLoading
- FacturaLoaded(List<Factura>)
- FacturaError(String message)
```

---

## 📊 Entidades del Dominio

### Usuario (Auth)

| Campo   | Tipo      | Descripción                      |
|---------|-----------|----------------------------------|
| id      | String    | Identificador único              |
| nombre  | String    | Nombre completo                  |
| email   | String    | Email de acceso                  |
| rol     | UserRole  | admin, vendedor, contador        |
| activo  | bool      | Estado de la cuenta              |

**Getters útiles:**
- `esAdmin`: bool
- `esVendedor`: bool
- `esContador`: bool

### Cliente

| Campo          | Tipo      | Requerido | Descripción                    |
|----------------|-----------|-----------|--------------------------------|
| id             | String    | ✅        | Identificador único            |
| nombre         | String    | ✅        | Nombre o razón social          |
| razonSocial    | String?   | ❌        | Razón social (opcional)        |
| identificacion | String    | ✅        | RUC, CI, Pasaporte             |
| email          | String?   | ❌        | Correo electrónico             |
| telefono       | String?   | ❌        | Teléfono de contacto           |
| direccion      | String?   | ❌        | Dirección física               |
| activo         | bool      | ✅        | Estado (default: true)         |
| fechaCreacion  | DateTime  | ✅        | Fecha de registro              |

### Producto

| Campo         | Tipo      | Requerido | Descripción                    |
|---------------|-----------|-----------|--------------------------------|
| id            | String    | ✅        | Identificador único            |
| codigo        | String    | ✅        | Código del producto            |
| nombre        | String    | ✅        | Nombre descriptivo             |
| descripcion   | String?   | ❌        | Descripción detallada          |
| precio        | double    | ✅        | Precio de venta                |
| costo         | double?   | ❌        | Costo de adquisición           |
| stock         | int       | ✅        | Cantidad en inventario         |
| categoria     | String?   | ❌        | Categoría del producto         |
| activo        | bool      | ✅        | Estado (default: true)         |
| fechaCreacion | DateTime  | ✅        | Fecha de creación              |

**Propiedades Calculadas:**
- `margen`: Porcentaje de ganancia
- `disponible`: Si está activo y tiene stock

### Factura

| Campo         | Tipo             | Descripción                    |
|---------------|------------------|--------------------------------|
| id            | String           | Identificador único            |
| clienteNombre | String           | Nombre del cliente             |
| total         | double           | Monto total                    |
| fecha         | DateTime         | Fecha de emisión               |
| items         | List<ItemFactura>| Items de la factura            |

### ItemFactura

| Campo           | Tipo   | Descripción                    |
|-----------------|--------|--------------------------------|
| descripcion     | String | Descripción del item           |
| cantidad        | int    | Cantidad                       |
| precioUnitario  | double | Precio por unidad              |

**Propiedades Calculadas:**
- `subtotal`: cantidad × precioUnitario

---

## 🔄 Gestión de Estado

El proyecto utiliza **BLoC (Business Logic Component)** para la gestión de estado.

### Patrón BLoC

```
┌──────────┐        ┌──────────┐        ┌──────────┐
│   UI     │─Event─>│   BLoC   │─State─>│   UI     │
│(Widget)  │        │(Business)│        │(Widget)  │
└──────────┘        └────┬─────┘        └──────────┘
                         │
                         ├─> UseCase
                         │
                         └─> Repository
```

### Estructura de un BLoC

Cada módulo tiene su BLoC con:

1. **Events**: Acciones del usuario
2. **States**: Estados de la UI
3. **BLoC**: Lógica de negocio

#### Ejemplo: ClienteBloc

**Events**
```dart
- GetClientesEvent()
- GetClienteEvent(String id)
- CreateClienteEvent(Cliente cliente)
- UpdateClienteEvent(Cliente cliente)
- DeleteClienteEvent(String id)
```

**States**
```dart
- ClienteInitial
- ClienteLoading
- ClienteLoaded(List<Cliente>)
- ClienteError(String message)
- ClienteCreating
- ClienteCreated(Cliente)
```

**Flujo**
```dart
ClienteBloc() {
  on<GetClientesEvent>(_onGetClientes);
  on<CreateClienteEvent>(_onCreate);
}

_onGetClientes(event, emit) async {
  emit(ClienteLoading());
  final result = await getClientesUseCase(NoParams());
  result.fold(
    (failure) => emit(ClienteError(failure.message)),
    (clientes) => emit(ClienteLoaded(clientes)),
  );
}
```

---

## 💉 Inyección de Dependencias

El proyecto usa **get_it** e **injectable** para la inyección de dependencias.

### Configuración

```dart
// injection_container.dart
final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  await getIt.init();
}
```

### Anotaciones Usadas

```dart
@injectable          // Clase inyectable
@lazySingleton       // Singleton lazy
@singleton           // Singleton eager
@LazySingleton(as: InterfaceType)  // Implementación de interfaz
```

### Ejemplo de Registro

```dart
// Repository
@LazySingleton(as: ClienteRepository)
class ClienteRepositoryImpl implements ClienteRepository {
  final ClienteRemoteDataSource remoteDataSource;
  final ClienteLocalDataSource localDataSource;
  
  ClienteRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
}

// UseCase
@injectable
class GetClientes implements UseCase<List<Cliente>, NoParams> {
  final ClienteRepository repository;
  
  GetClientes(this.repository);
}

// BLoC
@injectable
class ClienteBloc extends Bloc<ClienteEvent, ClienteState> {
  final GetClientes getClientes;
  final CreateCliente createCliente;
  
  ClienteBloc({
    required this.getClientes,
    required this.createCliente,
  });
}
```

### Uso en Widgets

```dart
BlocProvider(
  create: (_) => getIt<ClienteBloc>()..add(GetClientesEvent()),
  child: ClientesPage(),
)
```

---

## 🚦 Manejo de Errores

### Tipos de Failures

```dart
abstract class Failure {
  final String message;
}

class ServerFailure extends Failure       // Error del servidor
class CacheFailure extends Failure        // Error de cache local
class NetworkFailure extends Failure      // Sin conexión
class ValidationFailure extends Failure   // Validación de datos
```

### Patrón Either

Usando **dartz**, todas las operaciones retornan `Either<Failure, Success>`:

```dart
Future<Either<Failure, List<Cliente>>> getClientes();

// Uso
final result = await getClientesUseCase(NoParams());
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (clientes) => print('Éxito: ${clientes.length} clientes'),
);
```

### Flujo de Errores

```
UseCase → Repository → DataSource
   ↓         ↓            ↓
Either    Either      throw Exception
   ↓         ↓            ↓
 BLoC ← catch + Left(Failure)
   ↓
ErrorState → UI muestra error
```

---

## 🎨 Capa de Presentación

### Páginas Principales

#### 1. LoginPage
- Formulario de login
- Validación de campos
- Mensajes de error
- Usuarios de prueba visibles

#### 2. HomePage
- Dashboard con menú de módulos
- Acceso basado en roles
- Información del usuario
- Logout

#### 3. ClientesPage
- Lista de clientes
- Botón para crear nuevo
- Búsqueda/filtros
- Navegación a detalle

#### 4. CrearClientePage
- Formulario completo
- Validaciones
- Feedback de creación

#### 5. ProductosPage
- Catálogo de productos
- Información de stock
- Precios y márgenes

#### 6. FacturasPage
- Historial de facturas
- Detalles en diálogo
- Ordenamiento por fecha

#### 7. CrearFacturaPage
- Selector de cliente
- Lista de items
- Cálculo automático de totales
- Validaciones

### Widgets Reutilizables

- `ClienteListWidget`: Lista de clientes con cards
- `ProductoListWidget`: Grid de productos
- `FacturaListWidget`: Lista de facturas

---

## 🗄️ Capa de Datos

### Data Sources

#### Remote Data Source
Simula llamadas a API con datos mock:

```dart
@LazySingleton(as: ClienteRemoteDataSource)
class ClienteRemoteDataSourceImpl {
  Future<List<ClienteModel>> getClientes() async {
    await Future.delayed(Duration(seconds: 1));
    return _mockClientes;
  }
}
```

#### Local Data Source
Preparado para cache con SharedPreferences/Hive/SQLite:

```dart
@LazySingleton(as: ClienteLocalDataSource)
class ClienteLocalDataSourceImpl {
  Future<void> cacheClientes(List<ClienteModel> clientes) async {
    // TODO: Implementar persistencia local
  }
}
```

### Models

Extienden las entidades y añaden serialización:

```dart
@JsonSerializable()
class ClienteModel extends Cliente {
  const ClienteModel({...}) : super(...);
  
  factory ClienteModel.fromJson(Map<String, dynamic> json) =>
      _$ClienteModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ClienteModelToJson(this);
  
  factory ClienteModel.fromEntity(Cliente cliente) => ...;
}
```

### Repositories

Implementan la interfaz del dominio y orquestan data sources:

```dart
@LazySingleton(as: ClienteRepository)
class ClienteRepositoryImpl implements ClienteRepository {
  final ClienteRemoteDataSource remoteDataSource;
  final ClienteLocalDataSource localDataSource;

  @override
  Future<Either<Failure, List<Cliente>>> getClientes() async {
    try {
      final clientes = await remoteDataSource.getClientes();
      // await localDataSource.cacheClientes(clientes);
      return Right(clientes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

---

## 🧪 Testing

### Estructura Preparada

```
test/
├── core/
│   └── usecases/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── clientes/
│   ├── productos/
│   └── facturacion/
└── fixtures/              # Datos de prueba
```

### Tipos de Tests

1. **Unit Tests**: Lógica aislada (UseCases, Repositories)
2. **Widget Tests**: Componentes UI
3. **Integration Tests**: Flujos completos
4. **BLoC Tests**: Estados y transiciones

### Ejemplo de Test

```dart
void main() {
  late GetClientes useCase;
  late MockClienteRepository mockRepository;

  setUp(() {
    mockRepository = MockClienteRepository();
    useCase = GetClientes(mockRepository);
  });

  test('debe retornar lista de clientes', () async {
    // Arrange
    final tClientes = [Cliente(...)];
    when(() => mockRepository.getClientes())
        .thenAnswer((_) async => Right(tClientes));

    // Act
    final result = await useCase(NoParams());

    // Assert
    expect(result, Right(tClientes));
    verify(() => mockRepository.getClientes());
  });
}
```

---

## 🚀 Guía de Inicio

### Requisitos Previos

- Flutter SDK ^3.10.0
- Dart SDK ^3.10.0
- Android Studio / VS Code
- Dispositivo físico o emulador

### Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/velfin13/facturador-apollos-movile.git
cd facturador
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Generar código**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Ejecutar la aplicación**
```bash
flutter run
```

### Comandos Útiles

```bash
# Limpiar y obtener dependencias
flutter clean && flutter pub get

# Regenerar código (watch mode)
flutter pub run build_runner watch --delete-conflicting-outputs

# Analizar código
flutter analyze

# Ejecutar tests
flutter test

# Generar APK
flutter build apk --release

# Generar App Bundle
flutter build appbundle --release
```

### Configuración del IDE

#### VS Code
Extensiones recomendadas:
- Flutter
- Dart
- Bloc (Felix Angelov)
- Better Comments
- Error Lens

#### Android Studio
Plugins recomendados:
- Flutter
- Dart
- Flutter Bloc Snippets

---

## 📱 Navegación y Flujos

### Flujo de Autenticación

```
LoginPage
   ├─> Ingreso email/password
   ├─> Validación
   ├─> AuthBloc.add(LoginEvent)
   └─> Success → HomePage
```

### Flujo de Creación de Cliente

```
HomePage
   └─> Nuevo Cliente Button
       └─> CrearClientePage
           ├─> Formulario
           ├─> Validación
           ├─> ClienteBloc.add(CreateClienteEvent)
           └─> Success → Navigator.pop()
```

### Flujo de Facturación

```
HomePage
   └─> Nueva Factura Button
       └─> CrearFacturaPage
           ├─> Seleccionar Cliente
           ├─> Agregar Items
           │   ├─> Seleccionar Producto
           │   ├─> Especificar Cantidad
           │   └─> Calcular Subtotal
           ├─> Ver Total
           ├─> Guardar
           └─> Success → Mostrar Factura
```

---

## 🔐 Sistema de Permisos

### Roles y Accesos

| Módulo              | Admin | Vendedor | Contador |
|---------------------|-------|----------|----------|
| Ver Facturas        | ✅    | ❌       | ✅       |
| Crear Factura       | ✅    | ✅       | ❌       |
| Ver Clientes        | ✅    | ✅       | ❌       |
| Crear Cliente       | ✅    | ❌       | ❌       |
| Ver Productos       | ✅    | ✅       | ❌       |
| Crear Producto      | ✅    | ❌       | ❌       |
| Reportes            | ✅    | ❌       | ✅       |

### Implementación

```dart
// En HomePage
if (usuario.esAdmin)
  _buildMenuCard('Clientes', ...),

if (usuario.esAdmin || usuario.esVendedor)
  _buildMenuCard('Nueva Factura', ...),
```

---

## 🎯 Roadmap y TODOs

### ⚠️ TODOs Actuales

#### Capa de Datos
- [ ] Implementar cliente HTTP real (Dio/http)
- [ ] Configurar base URL de API
- [ ] Implementar cache local (Hive/SharedPreferences)
- [ ] Sincronización offline
- [ ] Manejo de tokens JWT
- [ ] Refresh token automático

#### Facturación
- [ ] Integración con SRI (Sistema de Rentas Internas Ecuador)
- [ ] Generación de XML para factura electrónica
- [ ] Firma electrónica
- [ ] Generación de PDF
- [ ] Envío por email
- [ ] Cálculo de impuestos (IVA)
- [ ] Descuentos y promociones
- [ ] Notas de crédito/débito

#### Productos
- [ ] Gestión de categorías
- [ ] Imágenes de productos
- [ ] Código de barras
- [ ] Control de lotes
- [ ] Historial de precios
- [ ] Alertas de stock bajo

#### Clientes
- [ ] Historial de compras
- [ ] Crédito y cuentas por cobrar
- [ ] Segmentación de clientes
- [ ] Múltiples direcciones
- [ ] Contactos adicionales

#### Reportes
- [ ] Ventas por período
- [ ] Productos más vendidos
- [ ] Análisis de clientes
- [ ] Estado de cuenta
- [ ] Gráficos y dashboards
- [ ] Exportar a Excel/PDF

#### UX/UI
- [ ] Tema oscuro
- [ ] Animaciones
- [ ] Búsqueda avanzada con filtros
- [ ] Paginación en listas grandes
- [ ] Pull to refresh
- [ ] Indicadores de carga skeleton

#### Testing
- [ ] Tests unitarios completos
- [ ] Widget tests
- [ ] Integration tests
- [ ] Mocks para todos los repositorios
- [ ] Coverage > 80%

#### DevOps
- [ ] CI/CD con GitHub Actions
- [ ] Deploy automático
- [ ] Versionado semántico
- [ ] Changelog automático
- [ ] Code review automatizado

### 🎯 Próximas Versiones

#### v1.1 - Integración Backend
- Conectar con API REST
- Autenticación JWT
- Persistencia real de datos

#### v1.2 - Facturación Electrónica
- Integración SRI
- Generación XML
- Firma electrónica

#### v1.3 - Reportes
- Dashboard con gráficos
- Exportación de reportes
- Análisis de ventas

#### v2.0 - Características Avanzadas
- Modo offline completo
- Múltiples empresas
- Multi-idioma
- Personalización de temas

---

## 📝 Convenciones de Código

### Nomenclatura

- **Archivos**: `snake_case.dart`
- **Clases**: `PascalCase`
- **Variables/Funciones**: `camelCase`
- **Constantes**: `camelCase` o `SCREAMING_SNAKE_CASE` para globales
- **Privados**: `_leadingUnderscore`

### Estructura de Archivos

```dart
// 1. Imports - organizados
import 'package:flutter/material.dart';        // Flutter
import 'package:flutter_bloc/flutter_bloc.dart'; // Paquetes externos
import 'core/...';                             // Core
import 'features/...';                         // Features

// 2. Clase principal
class MyWidget extends StatelessWidget {
  // 3. Propiedades finales
  final String title;
  
  // 4. Constructor
  const MyWidget({super.key, required this.title});
  
  // 5. Métodos públicos
  @override
  Widget build(BuildContext context) { ... }
  
  // 6. Métodos privados
  void _privateMethod() { ... }
}
```

### Comentarios

```dart
/// Documentación de clase o método público
/// 
/// Describe el propósito y uso
/// 
/// Ejemplo:
/// ```dart
/// final result = await getClientes(NoParams());
/// ```
class GetClientes { ... }

// TODO: Tarea pendiente
// FIXME: Bug a corregir
// HACK: Solución temporal
// NOTE: Nota importante
```

---

## 🐛 Troubleshooting

### Problemas Comunes

#### Error: "No se genera el código"
```bash
# Solución
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Error: "GetIt no encuentra la dependencia"
```bash
# Asegúrate de:
1. Tener @injectable en la clase
2. Ejecutar build_runner
3. Llamar a configureDependencies() en main()
```

#### Error: "BLoC no emite estados"
```dart
// Verifica:
1. Que el BLoC esté en un BlocProvider
2. Que uses BlocBuilder o BlocListener
3. Que emitas los estados correctamente
```

#### Error de compilación en modelos
```bash
# Regenerar modelos
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Flutter Docs](https://docs.flutter.dev/)
- [Dart Docs](https://dart.dev/guides)
- [BLoC Library](https://bloclibrary.dev/)
- [Get It](https://pub.dev/packages/get_it)
- [Injectable](https://pub.dev/packages/injectable)
- [Dartz](https://pub.dev/packages/dartz)

### Tutoriales Recomendados

- Clean Architecture in Flutter
- BLoC Pattern Essentials
- Dependency Injection with GetIt
- Functional Programming with Dartz

### Comunidad

- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit - r/FlutterDev](https://reddit.com/r/FlutterDev)

---

## 👥 Contribución

### Proceso

1. Fork del repositorio
2. Crear rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

### Estándares

- Seguir Clean Architecture
- Tests para nuevas características
- Documentar código público
- Actualizar DOCUMENTATION.md

---

## 📄 Licencia

Este proyecto es privado y pertenece a Apollos.

---

## 📞 Contacto

**Proyecto**: Facturador Apollos
**Repositorio**: https://github.com/velfin13/facturador-apollos-movile
**Mantenedor**: @velfin13

---

## 🎉 Agradecimientos

- Clean Architecture por Robert C. Martin
- BLoC Pattern por Felix Angelov
- Flutter Community

---

**Última actualización**: 19 de noviembre de 2025

**Versión del documento**: 1.0.0
