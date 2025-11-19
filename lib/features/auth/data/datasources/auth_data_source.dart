import 'package:injectable/injectable.dart';
import '../../domain/entities/usuario.dart';
import '../models/usuario_model.dart';

abstract class AuthLocalDataSource {
  Future<UsuarioModel?> getCurrentUser();
  Future<void> saveUser(UsuarioModel usuario);
  Future<void> clearUser();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  UsuarioModel? _currentUser;

  @override
  Future<UsuarioModel?> getCurrentUser() async {
    // En una app real, aquí leerías de SharedPreferences o secure storage
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<void> saveUser(UsuarioModel usuario) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = usuario;
  }

  @override
  Future<void> clearUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }
}

abstract class AuthRemoteDataSource {
  Future<UsuarioModel> login(String email, String password);
  Future<void> logout();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // Usuarios mock para pruebas
  final List<UsuarioModel> _mockUsers = [
    const UsuarioModel(
      id: '1',
      nombre: 'Admin Usuario',
      email: 'admin',
      rol: UserRole.admin,
    ),
    const UsuarioModel(
      id: '2',
      nombre: 'Carlos Vendedor',
      email: 'vendedor',
      rol: UserRole.vendedor,
    ),
    const UsuarioModel(
      id: '3',
      nombre: 'Ana Contadora',
      email: 'contador',
      rol: UserRole.contador,
    ),
  ];

  @override
  Future<UsuarioModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // Mock authentication - En producción validarías con el backend
    final user = _mockUsers.where((u) => u.email == email).firstOrNull;

    if (user == null) {
      throw Exception('Usuario no encontrado');
    }

    // Por simplicidad, aceptamos cualquier contraseña en el mock
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
