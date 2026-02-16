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
- ✅ Gestión de inventario/stock por bodega (ENTRADA/SALIDA)
- ✅ Generación de facturas con múltiples items y cálculo de IVA
- ✅ Visualización de historial de facturas con detalles
- ✅ Integración completa con API backend (.NET)
- ✅ Arquitectura limpia y escalable
- ✅ Manejo robusto de errores
- ✅ Responsive UI con padding dinámico (compatibilidad con navegación del sistema)
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

### Networking

- **dio**: ^5.7.0 - Cliente HTTP
- **pretty_dio_logger**: ^1.4.0 - Logs de peticiones HTTP
- **shared_preferences**: ^2.3.5 - Almacenamiento local de preferencias

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
│   │   ├── network/                       # Configuración de red
│   │   │   ├── api_config.dart            # URLs y configuración API
│   │   │   ├── api_exceptions.dart        # Excepciones HTTP
│   │   │   ├── dio_client.dart            # Cliente HTTP configurado
│   │   │   └── periodo_manager.dart       # Gestión del período actual
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
│       │       │   ├── productos_page.dart
│       │       │   ├── crear_producto_page.dart
│       │       │   └── ajustar_stock_page.dart
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

**Propósito**: Administración del inventario de productos, servicios y gestión de stock por bodega.

#### Características

- ✅ Catálogo de productos con stock
- ✅ Crear producto con validaciones (descripción, medidas, precios, IVA)
- ✅ Actualizar precios y datos del producto
- ✅ Gestión de inventario separada por bodega
- ✅ Ajustes de stock con motivo (ENTRADA/SALIDA)
- ✅ Múltiples precios (precio1, precio2, precio3)
- ✅ Código de barras
- ✅ Control de IVA (15%)
- ✅ Eliminar productos

#### Entidad Producto

```dart
class Producto {
  final String id;                 // idSysInProducto (generado por backend)
  final String periodo;            // Período fiscal
  final String descripcion;        // Descripción del producto
  final String medida;             // Unidad de medida (UND, KG, etc.)
  final double precio1;            // Precio de venta principal
  final double? precio2;           // Precio alternativo 1
  final double? precio3;           // Precio alternativo 2
  final double? costo;             // Costo de adquisición
  final String iva;                // 'S' o 'N' (aplica IVA 15%)
  final String? barra;             // Código de barras
  final bool activo;               // Estado del producto
  final double stock;              // Existencia total (calculado desde bodegas)
}
```

#### Gestión de Inventario/Stock

El sistema separa la **creación de productos** de la **gestión de stock**:

**AjustarStockPage**: Pantalla dedicada para ajustes de inventario
- Carga dinámica de bodegas desde API (`/api/Inventario/bodegas`)
- Selector de bodega (si hay múltiples) o display automático (si es una sola)
- Tipos de ajuste:
  - **ENTRADA**: Añadir stock (compras, devoluciones, ajustes positivos)
  - **SALIDA**: Reducir stock (ventas, daños, ajustes negativos)
- Validaciones:
  - En SALIDA: no permitir cantidad mayor al stock actual
  - Motivo obligatorio para trazabilidad
- Preview en tiempo real del nuevo stock
- Integración con API: `POST /api/Inventario/ajuste`

**Flujo de trabajo**:
1. Crear producto sin stock (stock = 0)
2. Desde la lista de productos, acceder al ajuste de stock (botón 📦)
3. Seleccionar bodega, tipo de ajuste, cantidad y motivo
4. Guardar ajuste → actualiza existencias en la bodega

#### Endpoints de API

- `POST /api/Productos`: Crear producto (sin stock)
- `GET /api/Productos?periodo={periodo}&filtro={texto}`: Listar productos
- `POST /api/Inventario/ajuste`: Ajustar stock
  ```json
  {
    "idSysPeriodo": "2025",
    "idSysInProducto": "PROD1",
    "idSysInBodega": "BOD1",
    "cantidadAjuste": 10.0,
    "tipoAjuste": "ENTRADA",
    "motivo": "Compra de mercadería"
  }
  ```
- `GET /api/Inventario/bodegas?periodo={periodo}`: Listar bodegas disponibles

---

### 4. Módulo de Facturación (`facturacion`)

**Propósito**: Creación y gestión de facturas con cálculo automático de IVA y totales.

#### Características

- ✅ Crear factura con múltiples items
- ✅ Selección de cliente desde catálogo
- ✅ Agregar productos desde inventario
- ✅ Cálculo automático de totales con IVA (15%)
- ✅ Desglose de subtotal, IVA y total
- ✅ Historial de facturas con detalles expandibles
- ✅ Ver detalle completo de factura
- ✅ Integración con API backend
- 🚧 Exportar PDF
- 🚧 Envío por email
- 🚧 Integración con SRI (Ecuador)

#### Entidades

**Factura**
```dart
class Factura {
  final String id;                    // idSysInVenta
  final String periodo;               // Período fiscal
  final String tipoDocumento;         // 'FAC', 'BOL', etc.
  final String numeroDocumento;       // Número de factura
  final String clienteId;             // idSysInCliente
  final String clienteNombre;         // Nombre del cliente
  final DateTime fecha;               // Fecha de emisión
  final double subtotal;              // Suma antes de IVA
  final double iva;                   // Monto de IVA (15%)
  final double total;                 // Total a pagar
  final String estado;                // 'Pendiente', 'Pagado', etc.
  final List<DetalleVenta> detalles;  // Items de la factura
}
```

**DetalleVenta**
```dart
class DetalleVenta {
  final String idSysInProducto;       // ID del producto
  final String descripcion;           // Descripción del producto
  final double cantidad;              // Cantidad vendida
  final double precioUnitario;        // Precio por unidad
  final String aplicaIva;             // 'S' o 'N'
  final double subtotal;              // cantidad × precioUnitario
  final double iva;                   // 15% si aplica
  final double total;                 // subtotal + iva
}
```

#### Cálculo de IVA

El sistema calcula automáticamente el IVA (15%) para productos que lo tienen configurado:

```dart
// Por cada item:
subtotal = cantidad × precioUnitario
iva = aplicaIva == 'S' ? subtotal × 0.15 : 0.0
total_item = subtotal + iva

// Total de la factura:
subtotal_factura = suma de todos los subtotales
iva_factura = suma de todos los IVA
total_factura = subtotal_factura + iva_factura
```

#### Flujo de Creación

1. **Seleccionar Cliente**: Dropdown con catálogo completo
2. **Agregar Items**: 
   - Seleccionar producto del inventario
   - El producto trae su precio y configuración de IVA
   - Especificar cantidad
   - Cálculo automático de subtotal, IVA y total por item
3. **Visualización en Tiempo Real**: 
   - Lista de items agregados con totales
   - Desglose: Subtotal, IVA (15%), Total
   - Botones de eliminar item
4. **Guardar Factura**: 
   - Validación de items (mínimo 1)
   - Validación de cliente seleccionado
   - Envío a API: `POST /api/Ventas`
   - Actualización automática del stock

#### Estados del BLoC

```dart
- FacturaInitial
- FacturaLoading
- FacturaLoaded(List<Factura>)
- FacturaDetailLoaded(Factura)  // Detalle de una factura específica
- FacturaError(String message)
- FacturaCreating
- FacturaCreated(Factura)
```

#### Endpoints de API

- `POST /api/Ventas`: Crear nueva factura/venta
  ```json
  {
    "idSysPeriodo": "2025",
    "idSysInCliente": "CLI1",
    "tipoDocumento": "FAC",
    "formaPago": "EFECTIVO",
    "fecha": "2025-11-19T10:30:00",
    "detalles": [
      {
        "idSysInProducto": "PROD1",
        "cantidad": 2,
        "precioUnitario": 10.50
      }
    ]
  }
  ```
- `GET /api/Ventas?periodo={periodo}&filtro={texto}`: Listar facturas
- `GET /api/Ventas/{id}`: Obtener detalle de factura

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
- Lista de clientes con integración API
- Botón para crear nuevo
- Búsqueda/filtros
- Navegación a detalle

#### 4. CrearClientePage
- Formulario completo
- Validaciones de campos obligatorios
- Feedback de creación con SnackBar
- Padding dinámico para evitar ocultamiento por navegación del sistema

#### 5. ProductosPage
- Catálogo de productos desde API
- Información de stock actual
- Botón de crear nuevo producto
- Acceso rápido a ajuste de inventario (📦) por producto

#### 6. CrearProductoPage
- Formulario completo: descripción, medida, precios (1, 2, 3)
- Costo, IVA, código de barras
- Nota: stock se gestiona desde módulo de inventario
- Validaciones de campos requeridos
- Padding dinámico para botones

#### 7. AjustarStockPage
- Carga dinámica de bodegas desde API
- Selector de bodega (si hay múltiples) o display automático
- Tipos de ajuste: ENTRADA / SALIDA
- Validación de cantidad (SALIDA no puede exceder stock)
- Campo de motivo obligatorio
- Preview en tiempo real del nuevo stock
- Padding dinámico en botones

#### 8. FacturasPage
- Historial de facturas desde API
- Cards expandibles con detalles completos
- Información: cliente, fecha, subtotal, IVA, total
- Lista de items con cantidades y precios
- Ordenamiento por fecha

#### 9. CrearFacturaPage
- Selector de cliente desde catálogo API
- Selector de productos desde inventario API
- Agregar múltiples items con cantidad
- Cálculo automático en tiempo real:
  - Subtotal por item
  - IVA (15%) si aplica
  - Total por item
  - Subtotal, IVA y total de la factura
- Validaciones de cliente e items
- Botón para eliminar items
- Padding dinámico en sección de totales y botones

### Widgets Reutilizables

- `ClienteListWidget`: Lista de clientes con cards
- `ProductoListWidget`: Grid de productos
- `FacturaListWidget`: Lista de facturas

---

## 🗄️ Capa de Datos

### Data Sources

#### Remote Data Source
Integración completa con API backend usando DioClient:

```dart
@LazySingleton(as: ClienteRemoteDataSource)
class ClienteRemoteDataSourceImpl implements ClienteRemoteDataSource {
  final DioClient dioClient;
  final PeriodoManager periodoManager;
  
  ClienteRemoteDataSourceImpl({
    required this.dioClient,
    required this.periodoManager,
  });
  
  @override
  Future<List<ClienteModel>> getClientes({String? filtro}) async {
    final response = await dioClient.get(
      '/Clientes',
      queryParameters: {
        'periodo': periodoManager.periodoActual,
        if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
      },
    );
    
    if (response.data is Map && response.data['data'] != null) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => ClienteModel.fromJson(json)).toList();
    }
    return [];
  }
  
  @override
  Future<void> createCliente(ClienteModel cliente) async {
    await dioClient.post('/Clientes', data: cliente.toJson());
  }
}
```

#### DioClient
Cliente HTTP configurado con:
- Base URL configurable
- Timeouts (conexión: 30s, recepción: 30s)
- Pretty logger para desarrollo
- Manejo automático de errores con ApiException
- Métodos: GET, POST, PUT, DELETE

#### PeriodoManager
Gestión del período fiscal actual:
- Almacenamiento en SharedPreferences
- Default: año actual
- Usado en todas las peticiones de API

#### Local Data Source
Preparado para cache con SharedPreferences (pendiente de implementación completa):

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

### ✅ Completado

#### Capa de Datos
- ✅ Implementar cliente HTTP real (Dio)
- ✅ Configurar base URL de API
- ✅ Manejo de excepciones HTTP
- ✅ PeriodoManager para gestión de período fiscal
- ✅ Pretty logger para debugging

#### Productos
- ✅ Crear producto con validaciones completas
- ✅ Múltiples precios (precio1, precio2, precio3)
- ✅ Código de barras
- ✅ Control de IVA por producto
- ✅ Gestión de inventario/stock separada
- ✅ Ajustes de stock por bodega (ENTRADA/SALIDA)
- ✅ Carga dinámica de bodegas desde API
- ✅ Validación de stock en salidas

#### Clientes
- ✅ CRUD completo con API
- ✅ Formulario de creación validado
- ✅ Listado desde API con filtros

#### Facturación
- ✅ Creación de facturas con API
- ✅ Cálculo automático de IVA (15%)
- ✅ Desglose de subtotal, IVA y total
- ✅ Múltiples items por factura
- ✅ Listado de facturas desde API
- ✅ Detalles expandibles de facturas

#### UI/UX
- ✅ Padding dinámico en formularios (MediaQuery.padding.bottom)
- ✅ Evitar ocultamiento de botones por navegación del sistema
- ✅ Indicadores de carga
- ✅ Feedback con SnackBars

### ⚠️ TODOs Pendientes

#### Capa de Datos
- [ ] Implementar cache local completo (Hive/SharedPreferences)
- [ ] Sincronización offline
- [ ] Manejo de tokens JWT para autenticación
- [ ] Refresh token automático

#### Facturación
- [ ] Integración con SRI (Sistema de Rentas Internas Ecuador)
- [ ] Generación de XML para factura electrónica
- [ ] Firma electrónica
- [ ] Generación de PDF
- [ ] Envío por email
- [ ] Descuentos y promociones
- [ ] Notas de crédito/débito
- [ ] Formas de pago adicionales

#### Productos
- [ ] Gestión de categorías
- [ ] Imágenes de productos
- [ ] Control de lotes
- [ ] Historial de precios
- [ ] Alertas de stock bajo
- [ ] Reporte de movimientos de inventario

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
- [ ] Animaciones mejoradas
- [ ] Búsqueda avanzada con más filtros
- [ ] Paginación en listas grandes
- [ ] Pull to refresh
- [ ] Indicadores de carga skeleton
- [ ] Validación de campos en tiempo real

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

#### v1.0 - ACTUAL ✅
- ✅ Integración completa con API backend (.NET)
- ✅ CRUD de clientes, productos y facturas
- ✅ Gestión de inventario por bodega
- ✅ Cálculo automático de IVA
- ✅ UI responsive con padding dinámico

#### v1.1 - Mejoras de UX (En Progreso)
- [ ] Autenticación JWT con la API
- [ ] Tema oscuro
- [ ] Cache local completo
- [ ] Modo offline básico

#### v1.2 - Facturación Electrónica
- [ ] Integración SRI
- [ ] Generación XML
- [ ] Firma electrónica
- [ ] Generación de PDF

#### v1.3 - Reportes
- [ ] Dashboard con gráficos
- [ ] Exportación de reportes
- [ ] Análisis de ventas
- [ ] Reporte de inventario

#### v2.0 - Características Avanzadas
- [ ] Modo offline completo con sincronización
- [ ] Múltiples empresas
- [ ] Multi-idioma
- [ ] Personalización de temas
- [ ] Notificaciones push

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

## 🔌 Configuración de la API

### URL Base

Por defecto: `http://192.168.0.106:5117/api`

Para cambiar la URL, edita `lib/core/network/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'TU_URL_AQUI';
  // ...
}
```

### Endpoints Principales

| Módulo | Método | Endpoint | Descripción |
|--------|--------|----------|-------------|
| Clientes | GET | `/Clientes?periodo={periodo}&filtro={texto}` | Listar clientes |
| Clientes | POST | `/Clientes` | Crear cliente |
| Productos | GET | `/Productos?periodo={periodo}&filtro={texto}` | Listar productos |
| Productos | POST | `/Productos` | Crear producto |
| Inventario | GET | `/Inventario/bodegas?periodo={periodo}` | Listar bodegas |
| Inventario | POST | `/Inventario/ajuste` | Ajustar stock |
| Ventas | GET | `/Ventas?periodo={periodo}&filtro={texto}` | Listar facturas |
| Ventas | POST | `/Ventas` | Crear factura |
| Ventas | GET | `/Ventas/{id}` | Detalle de factura |

### Modelos de Request

#### Crear Cliente
```json
{
  "idSysPeriodo": "2025",
  "nombre": "Cliente Ejemplo",
  "ruc": "1234567890001",
  "email": "cliente@ejemplo.com",
  "telefono": "0999999999",
  "direccion": "Av. Principal 123"
}
```

#### Crear Producto
```json
{
  "idSysPeriodo": "2025",
  "descripcion": "Producto de Prueba",
  "medida": "UND",
  "precio1": 10.50,
  "precio2": 9.50,
  "precio3": 8.50,
  "costo": 5.00,
  "iva": "S",
  "barra": "1234567890123"
}
```

#### Ajustar Stock
```json
{
  "idSysPeriodo": "2025",
  "idSysInProducto": "PROD1",
  "idSysInBodega": "BOD1",
  "cantidadAjuste": 10.0,
  "tipoAjuste": "ENTRADA",
  "motivo": "Compra de mercadería"
}
```

#### Crear Factura/Venta
```json
{
  "idSysPeriodo": "2025",
  "idSysInCliente": "CLI1",
  "tipoDocumento": "FAC",
  "formaPago": "EFECTIVO",
  "fecha": "2025-11-19T10:30:00",
  "detalles": [
    {
      "idSysInProducto": "PROD1",
      "cantidad": 2,
      "precioUnitario": 10.50
    }
  ]
}
```

---

**Última actualización**: 19 de noviembre de 2025

**Versión del documento**: 2.0.0

**Versión de la app**: 1.0.0
