// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../core/network/dio_client.dart' as _i393;
import '../core/network/periodo_manager.dart' as _i744;
import '../features/auth/data/datasources/auth_data_source.dart' as _i489;
import '../features/auth/data/repositories/auth_repository_impl.dart' as _i570;
import '../features/auth/domain/repositories/auth_repository.dart' as _i869;
import '../features/auth/domain/usecases/get_current_user.dart' as _i318;
import '../features/auth/domain/usecases/login.dart' as _i625;
import '../features/auth/domain/usecases/logout.dart' as _i338;
import '../features/auth/presentation/bloc/auth_bloc.dart' as _i59;
import '../features/clientes/data/datasources/cliente_remote_data_source.dart'
    as _i478;
import '../features/clientes/data/repositories/cliente_repository_impl.dart'
    as _i629;
import '../features/clientes/domain/repositories/cliente_repository.dart'
    as _i135;
import '../features/clientes/domain/usecases/create_cliente.dart' as _i799;
import '../features/clientes/domain/usecases/get_clientes.dart' as _i943;
import '../features/clientes/presentation/bloc/cliente_bloc.dart' as _i454;
import '../features/facturacion/data/datasources/factura_local_data_source.dart'
    as _i865;
import '../features/facturacion/data/datasources/factura_remote_data_source.dart'
    as _i264;
import '../features/facturacion/data/repositories/factura_repository_impl.dart'
    as _i282;
import '../features/facturacion/domain/repositories/factura_repository.dart'
    as _i757;
import '../features/facturacion/domain/usecases/create_factura.dart' as _i281;
import '../features/facturacion/domain/usecases/get_factura.dart' as _i756;
import '../features/facturacion/domain/usecases/get_facturas.dart' as _i92;
import '../features/facturacion/presentation/bloc/factura_bloc.dart' as _i246;
import '../features/productos/data/datasources/producto_remote_data_source.dart'
    as _i960;
import '../features/productos/data/repositories/producto_repository_impl.dart'
    as _i79;
import '../features/productos/domain/repositories/producto_repository.dart'
    as _i797;
import '../features/productos/domain/usecases/create_producto.dart' as _i852;
import '../features/productos/domain/usecases/get_productos.dart' as _i223;
import '../features/productos/presentation/bloc/producto_bloc.dart' as _i829;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i393.DioClient>(() => _i393.DioClient());
    gh.lazySingleton<_i865.FacturaLocalDataSource>(
      () => _i865.FacturaLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i489.AuthRemoteDataSource>(
      () => _i489.AuthRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i744.PeriodoManager>(
      () => _i744.PeriodoManager(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i489.AuthLocalDataSource>(
      () => _i489.AuthLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i478.ClienteRemoteDataSource>(
      () => _i478.ClienteRemoteDataSourceImpl(
        gh<_i393.DioClient>(),
        gh<_i744.PeriodoManager>(),
      ),
    );
    gh.lazySingleton<_i264.FacturaRemoteDataSource>(
      () => _i264.FacturaRemoteDataSourceImpl(
        gh<_i393.DioClient>(),
        gh<_i744.PeriodoManager>(),
      ),
    );
    gh.lazySingleton<_i960.ProductoRemoteDataSource>(
      () => _i960.ProductoRemoteDataSourceImpl(
        gh<_i393.DioClient>(),
        gh<_i744.PeriodoManager>(),
      ),
    );
    gh.lazySingleton<_i869.AuthRepository>(
      () => _i570.AuthRepositoryImpl(
        remoteDataSource: gh<_i489.AuthRemoteDataSource>(),
        localDataSource: gh<_i489.AuthLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i757.FacturaRepository>(
      () => _i282.FacturaRepositoryImpl(
        remoteDataSource: gh<_i264.FacturaRemoteDataSource>(),
        localDataSource: gh<_i865.FacturaLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i135.ClienteRepository>(
      () => _i629.ClienteRepositoryImpl(
        remoteDataSource: gh<_i478.ClienteRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i797.ProductoRepository>(
      () => _i79.ProductoRepositoryImpl(
        remoteDataSource: gh<_i960.ProductoRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i799.CreateCliente>(
      () => _i799.CreateCliente(gh<_i135.ClienteRepository>()),
    );
    gh.lazySingleton<_i943.GetClientes>(
      () => _i943.GetClientes(gh<_i135.ClienteRepository>()),
    );
    gh.factory<_i852.CreateProducto>(
      () => _i852.CreateProducto(gh<_i797.ProductoRepository>()),
    );
    gh.lazySingleton<_i223.GetProductos>(
      () => _i223.GetProductos(gh<_i797.ProductoRepository>()),
    );
    gh.factory<_i756.GetFactura>(
      () => _i756.GetFactura(gh<_i757.FacturaRepository>()),
    );
    gh.lazySingleton<_i281.CreateFactura>(
      () => _i281.CreateFactura(gh<_i757.FacturaRepository>()),
    );
    gh.lazySingleton<_i92.GetFacturas>(
      () => _i92.GetFacturas(gh<_i757.FacturaRepository>()),
    );
    gh.lazySingleton<_i318.GetCurrentUser>(
      () => _i318.GetCurrentUser(gh<_i869.AuthRepository>()),
    );
    gh.lazySingleton<_i625.Login>(
      () => _i625.Login(gh<_i869.AuthRepository>()),
    );
    gh.lazySingleton<_i338.Logout>(
      () => _i338.Logout(gh<_i869.AuthRepository>()),
    );
    gh.factory<_i454.ClienteBloc>(
      () => _i454.ClienteBloc(
        getClientes: gh<_i943.GetClientes>(),
        createCliente: gh<_i799.CreateCliente>(),
      ),
    );
    gh.factory<_i829.ProductoBloc>(
      () => _i829.ProductoBloc(
        getProductos: gh<_i223.GetProductos>(),
        createProducto: gh<_i852.CreateProducto>(),
      ),
    );
    gh.factory<_i246.FacturaBloc>(
      () => _i246.FacturaBloc(
        getFacturas: gh<_i92.GetFacturas>(),
        getFactura: gh<_i756.GetFactura>(),
        createFactura: gh<_i281.CreateFactura>(),
      ),
    );
    gh.factory<_i59.AuthBloc>(
      () => _i59.AuthBloc(
        loginUseCase: gh<_i625.Login>(),
        logoutUseCase: gh<_i338.Logout>(),
        getCurrentUser: gh<_i318.GetCurrentUser>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
