import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/business/business_setup_service.dart';
import '../../domain/entities/usuario.dart';
import '../bloc/auth_bloc.dart';

class NegocioSetupPage extends StatefulWidget {
  final Usuario usuario;
  final BusinessSetupService businessSetupService;
  final VoidCallback onCompleted;
  final VoidCallback onSkip;

  const NegocioSetupPage({
    super.key,
    required this.usuario,
    required this.businessSetupService,
    required this.onCompleted,
    required this.onSkip,
  });

  @override
  State<NegocioSetupPage> createState() => _NegocioSetupPageState();
}

class _NegocioSetupPageState extends State<NegocioSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _rucCtrl = TextEditingController();
  final _razonCtrl = TextEditingController();
  final _nombreComercialCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _establecimientoCtrl = TextEditingController(text: 'Matriz');
  final _codigoEstabCtrl = TextEditingController(text: '001');
  final _puntoEmisionCtrl = TextEditingController(text: '001');

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _razonCtrl.text = widget.usuario.nombre;
    _nombreComercialCtrl.text = widget.usuario.nombre;
  }

  @override
  void dispose() {
    _rucCtrl.dispose();
    _razonCtrl.dispose();
    _nombreComercialCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _establecimientoCtrl.dispose();
    _codigoEstabCtrl.dispose();
    _puntoEmisionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registra Tu Negocio'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthBloc>().add(LogoutEvent()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Antes de crear productos y facturas, registra los datos de tu negocio.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _rucCtrl,
                  label: 'RUC',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'RUC requerido';
                    if (value.length != 13) return 'RUC debe tener 13 dígitos';
                    if (int.tryParse(value) == null) return 'RUC inválido';
                    return null;
                  },
                ),
                _buildField(
                  controller: _razonCtrl,
                  label: 'Razón social',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),
                _buildField(
                  controller: _nombreComercialCtrl,
                  label: 'Nombre comercial',
                ),
                _buildField(
                  controller: _telefonoCtrl,
                  label: 'Teléfono',
                  keyboardType: TextInputType.phone,
                ),
                _buildField(controller: _direccionCtrl, label: 'Dirección'),
                _buildField(
                  controller: _establecimientoCtrl,
                  label: 'Nombre establecimiento',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _codigoEstabCtrl,
                        label: 'Cod. Est.',
                        keyboardType: TextInputType.number,
                        validator: _validateCodigo3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _puntoEmisionCtrl,
                        label: 'Punto Emisión',
                        keyboardType: TextInputType.number,
                        validator: _validateCodigo3,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.store),
                  label: Text(
                    _isSaving ? 'Registrando...' : 'Registrar negocio',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isSaving ? null : widget.onSkip,
                  child: const Text('Omitir por ahora'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String? _validateCodigo3(String? value) {
    final text = (value ?? '').trim();
    if (text.length != 3) return 'Debe tener 3 dígitos';
    if (int.tryParse(text) == null) return 'Solo números';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final payload = BusinessRegistrationInput(
        ruc: _rucCtrl.text.trim(),
        razonSocial: _razonCtrl.text.trim(),
        nombreComercial: _nombreComercialCtrl.text.trim(),
        email: widget.usuario.email,
        telefono: _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty
            ? null
            : _direccionCtrl.text.trim(),
        nombreEstablecimiento: _establecimientoCtrl.text.trim(),
        codigoEstablecimiento: _codigoEstabCtrl.text.trim(),
        codigoPuntoEmision: _puntoEmisionCtrl.text.trim(),
      );

      await widget.businessSetupService.registerBusiness(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negocio registrado correctamente')),
      );
      widget.onCompleted();
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? (responseData['message']?.toString() ??
                responseData['errors']?.toString() ??
                e.message)
          : e.message;
      setState(() {
        _error = message ?? 'No se pudo registrar el negocio';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
