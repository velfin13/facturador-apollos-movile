import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../network/dio_client.dart';
import '../network/periodo_manager.dart';

enum BusinessSetupState { completed, requiresSetup }

class BusinessRegistrationInput {
  final String ruc;
  final String razonSocial;
  final String? nombreComercial;
  final String? email;
  final String? telefono;
  final String? direccion;
  final String nombreEstablecimiento;
  final String codigoEstablecimiento;
  final String codigoPuntoEmision;

  const BusinessRegistrationInput({
    required this.ruc,
    required this.razonSocial,
    this.nombreComercial,
    this.email,
    this.telefono,
    this.direccion,
    required this.nombreEstablecimiento,
    required this.codigoEstablecimiento,
    required this.codigoPuntoEmision,
  });
}

@lazySingleton
class BusinessSetupService {
  final DioClient _dioClient;
  final PeriodoManager _periodoManager;
  static const String _freePlanId = '11111111-1111-1111-1111-111111111201';

  BusinessSetupService(this._dioClient, this._periodoManager);

  Future<BusinessSetupState> evaluateSetup() async {
    final empresas = await _getEmpresas();
    if (empresas.isEmpty) {
      return BusinessSetupState.requiresSetup;
    }

    final periodo = _extractPeriodo(empresas.first) ?? 1;
    await _periodoManager.setPeriodo(periodo.toString());
    return BusinessSetupState.completed;
  }

  Future<void> registerBusiness(BusinessRegistrationInput input) async {
    await _ensureTenant(input);
    await _ensureDefaultSubscription(input);
    final idSysPeriodo = await _createEmpresa(input);
    if (idSysPeriodo != null) {
      await _periodoManager.setPeriodo(idSysPeriodo.toString());
    }
  }

  Future<List<Map<String, dynamic>>> _getEmpresas() async {
    final response = await _dioClient.get('/Empresas');
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    return const [];
  }

  int? _extractPeriodo(Map<String, dynamic> empresa) {
    final value = empresa['idSysPeriodo'] ?? empresa['id_sys_periodo'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _ensureTenant(BusinessRegistrationInput input) async {
    try {
      await _dioClient.get('/Tenants/current');
      return;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    await _dioClient.post(
      '/Tenants/ensure',
      data: {
        'ruc': input.ruc,
        'nombre': input.razonSocial,
        'nombreComercial': input.nombreComercial ?? input.razonSocial,
        'email': input.email,
        'telefono': input.telefono,
        'direccion': input.direccion,
        'obligadoContabilidad': 'SI',
        'tipoContribuyente': '01',
      },
    );
  }

  Future<int?> _createEmpresa(BusinessRegistrationInput input) async {
    final response = await _dioClient.post(
      '/Empresas',
      data: {
        'codigoEstablecimiento': input.codigoEstablecimiento,
        'codigoPuntoEmision': input.codigoPuntoEmision,
        'nombreEstablecimiento': input.nombreEstablecimiento,
        'direccionEstablecimiento': input.direccion,
        'telefonoEstablecimiento': input.telefono,
        'emailEstablecimiento': input.email,
        'ambienteSri': 'PRUEBAS',
      },
    );

    final data = response.data;
    if (data is Map && data['data'] is Map) {
      final payload = (data['data'] as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
      return _extractPeriodo(payload);
    }

    return null;
  }

  Future<void> _ensureDefaultSubscription(
    BusinessRegistrationInput input,
  ) async {
    final canCreateCompany = await _canCreateCompany();
    if (canCreateCompany) {
      return;
    }

    final customerEmail =
        (input.email != null && input.email!.trim().isNotEmpty)
        ? input.email!.trim()
        : '${input.ruc}@apolos.local';

    try {
      await _dioClient.post(
        '/Subscriptions/create',
        data: {
          'planId': _freePlanId,
          'planName': 'GRATUITO',
          'amount': 0,
          'currency': 'USD',
          'description': 'Suscripción gratuita inicial',
          'returnUrl': 'com.apollos.facturador://subscription-return',
          'cancelUrl': 'com.apollos.facturador://subscription-cancel',
          'customerEmail': customerEmail,
          'customerName': input.razonSocial,
          'billingPeriod': 'MENSUAL',
        },
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? (responseData['message']?.toString() ?? '')
          : '';

      // Ya tiene una suscripción activa o pendiente válida.
      final normalized = message.toUpperCase();
      if (normalized.contains('ACTIVE SUBSCRIPTION') ||
          normalized.contains('PAGO PENDIENTE') ||
          normalized.contains('PENDIENTE')) {
        return;
      }
      rethrow;
    }

    final canCreateAfter = await _canCreateCompany();
    if (!canCreateAfter) {
      throw Exception(
        'No se pudo activar el plan gratuito por defecto para tu cuenta.',
      );
    }
  }

  Future<bool> _canCreateCompany() async {
    final response = await _dioClient.get('/Subscriptions/can-create-company');
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      final payload = (data['data'] as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
      final value = payload['canCreateCompany'];
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
    }
    return false;
  }
}
