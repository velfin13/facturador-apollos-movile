import 'package:injectable/injectable.dart';
import '../models/producto_model.dart';

abstract class ProductoRemoteDataSource {
  Future<List<ProductoModel>> getProductos();
  Future<ProductoModel> getProducto(String id);
  Future<ProductoModel> createProducto(ProductoModel producto);
  Future<ProductoModel> updateProducto(ProductoModel producto);
  Future<void> deleteProducto(String id);
}

@LazySingleton(as: ProductoRemoteDataSource)
class ProductoRemoteDataSourceImpl implements ProductoRemoteDataSource {
  @override
  Future<List<ProductoModel>> getProductos() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      ProductoModel(
        id: '1',
        codigo: 'PROD001',
        nombre: 'Laptop Dell',
        descripcion: 'Laptop Dell Inspiron 15, 8GB RAM, 256GB SSD',
        precio: 850.00,
        costo: 600.00,
        stock: 15,
        categoria: 'Electrónica',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 90)),
      ),
      ProductoModel(
        id: '2',
        codigo: 'PROD002',
        nombre: 'Mouse Logitech',
        descripcion: 'Mouse inalámbrico Logitech M185',
        precio: 25.00,
        costo: 15.00,
        stock: 50,
        categoria: 'Accesorios',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 60)),
      ),
      ProductoModel(
        id: '3',
        codigo: 'PROD003',
        nombre: 'Teclado Mecánico',
        descripcion: 'Teclado mecánico RGB para gaming',
        precio: 120.00,
        costo: 80.00,
        stock: 25,
        categoria: 'Accesorios',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 45)),
      ),
      ProductoModel(
        id: '4',
        codigo: 'PROD004',
        nombre: 'Monitor LG 24"',
        descripcion: 'Monitor LG 24" Full HD IPS',
        precio: 280.00,
        costo: 200.00,
        stock: 10,
        categoria: 'Electrónica',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ProductoModel(
        id: '5',
        codigo: 'PROD005',
        nombre: 'Webcam HD',
        descripcion: 'Webcam HD 1080p',
        precio: 45.00,
        costo: 30.00,
        stock: 0,
        categoria: 'Accesorios',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  @override
  Future<ProductoModel> getProducto(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final productos = await getProductos();
    return productos.firstWhere((p) => p.id == id);
  }

  @override
  Future<ProductoModel> createProducto(ProductoModel producto) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return producto;
  }

  @override
  Future<ProductoModel> updateProducto(ProductoModel producto) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return producto;
  }

  @override
  Future<void> deleteProducto(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
