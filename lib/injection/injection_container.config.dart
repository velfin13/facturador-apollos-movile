// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:facturador/features/auth/data/datasources/auth_data_source.dart'
    as _i804;
import 'package:facturador/features/auth/data/repositories/auth_repository_impl.dart'
    as _i514;
import 'package:facturador/features/auth/domain/repositories/auth_repository.dart'
    as _i109;
import 'package:facturador/features/auth/domain/usecases/get_current_user.dart'
    as _i942;
import 'package:facturador/features/auth/domain/usecases/login.dart' as _i610;
import 'package:facturador/features/auth/domain/usecases/logout.dart' as _i393;
import 'package:facturador/features/auth/presentation/bloc/auth_bloc.dart'
    as _i1000;
import 'package:facturador/features/clientes/data/datasources/cliente_remote_data_source.dart'
    as _i834;
import 'package:facturador/features/clientes/data/repositories/cliente_repository_impl.dart'
    as _i633;
import 'package:facturador/features/clientes/domain/repositories/cliente_repository.dart'
    as _i340;
import 'package:facturador/features/clientes/domain/usecases/get_clientes.dart'
    as _i244;
import 'package:facturador/features/clientes/presentation/bloc/cliente_bloc.dart'
    as _i396;
import 'package:facturador/features/facturacion/data/datasources/factura_local_data_source.dart'
    as _i220;
import 'package:facturador/features/facturacion/data/datasources/factura_remote_data_source.dart'
    as _i605;
import 'package:facturador/features/facturacion/data/repositories/factura_repository_impl.dart'
    as _i231;
import 'package:facturador/features/facturacion/domain/repositories/factura_repository.dart'
    as _i931;
import 'package:facturador/features/facturacion/domain/usecases/get_facturas.dart'
    as _i413;
import 'package:facturador/features/facturacion/presentation/bloc/factura_bloc.dart'
    as _i206;
import 'package:facturador/features/productos/data/datasources/producto_remote_data_source.dart'
    as _i554;
import 'package:facturador/features/productos/data/repositories/producto_repository_impl.dart'
    as _i999;
import 'package:facturador/features/productos/domain/repositories/producto_repository.dart'
    as _i925;
import 'package:facturador/features/productos/domain/usecases/get_productos.dart'
    as _i660;
import 'package:facturador/features/productos/presentation/bloc/producto_bloc.dart'
    as _i209;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i220.FacturaLocalDataSource>(
      () => _i220.FacturaLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i804.AuthRemoteDataSource>(
      () => _i804.AuthRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i554.ProductoRemoteDataSource>(
      () => _i554.ProductoRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i605.FacturaRemoteDataSource>(
      () => _i605.FacturaRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i834.ClienteRemoteDataSource>(
      () => _i834.ClienteRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i804.AuthLocalDataSource>(
      () => _i804.AuthLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i340.ClienteRepository>(
      () => _i633.ClienteRepositoryImpl(
        remoteDataSource: gh<_i834.ClienteRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i925.ProductoRepository>(
      () => _i999.ProductoRepositoryImpl(
        remoteDataSource: gh<_i554.ProductoRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i244.GetClientes>(
      () => _i244.GetClientes(gh<_i340.ClienteRepository>()),
    );
    gh.lazySingleton<_i660.GetProductos>(
      () => _i660.GetProductos(gh<_i925.ProductoRepository>()),
    );
    gh.lazySingleton<_i109.AuthRepository>(
      () => _i514.AuthRepositoryImpl(
        remoteDataSource: gh<_i804.AuthRemoteDataSource>(),
        localDataSource: gh<_i804.AuthLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i931.FacturaRepository>(
      () => _i231.FacturaRepositoryImpl(
        remoteDataSource: gh<_i605.FacturaRemoteDataSource>(),
        localDataSource: gh<_i220.FacturaLocalDataSource>(),
      ),
    );
    gh.factory<_i396.ClienteBloc>(
      () => _i396.ClienteBloc(getClientes: gh<_i244.GetClientes>()),
    );
    gh.factory<_i209.ProductoBloc>(
      () => _i209.ProductoBloc(getProductos: gh<_i660.GetProductos>()),
    );
    gh.lazySingleton<_i413.GetFacturas>(
      () => _i413.GetFacturas(gh<_i931.FacturaRepository>()),
    );
    gh.lazySingleton<_i942.GetCurrentUser>(
      () => _i942.GetCurrentUser(gh<_i109.AuthRepository>()),
    );
    gh.lazySingleton<_i610.Login>(
      () => _i610.Login(gh<_i109.AuthRepository>()),
    );
    gh.lazySingleton<_i393.Logout>(
      () => _i393.Logout(gh<_i109.AuthRepository>()),
    );
    gh.factory<_i206.FacturaBloc>(
      () => _i206.FacturaBloc(getFacturas: gh<_i413.GetFacturas>()),
    );
    gh.factory<_i1000.AuthBloc>(
      () => _i1000.AuthBloc(
        loginUseCase: gh<_i610.Login>(),
        logoutUseCase: gh<_i393.Logout>(),
        getCurrentUser: gh<_i942.GetCurrentUser>(),
      ),
    );
    return this;
  }
}
