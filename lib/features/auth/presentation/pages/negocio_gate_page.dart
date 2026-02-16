import 'package:flutter/material.dart';
import '../../../../core/business/business_setup_service.dart';
import '../../../../injection/injection_container.dart';
import '../../domain/entities/usuario.dart';
import 'home_page.dart';
import 'negocio_setup_page.dart';

class NegocioGatePage extends StatefulWidget {
  final Usuario usuario;

  const NegocioGatePage({super.key, required this.usuario});

  @override
  State<NegocioGatePage> createState() => _NegocioGatePageState();
}

class _NegocioGatePageState extends State<NegocioGatePage> {
  final BusinessSetupService _service = getIt<BusinessSetupService>();
  BusinessSetupState? _state;
  bool _skipped = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _state = null;
      _skipped = false;
    });
    try {
      final status = await _service.evaluateSetup();
      if (!mounted) return;
      setState(() => _state = status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == BusinessSetupState.completed) {
      return HomePage(usuario: widget.usuario);
    }

    if (_skipped) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro Pendiente')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 58),
                const SizedBox(height: 12),
                Text(
                  'Debes registrar tu negocio para usar el sistema.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes hacerlo ahora o más tarde, pero no podrás crear productos, clientes o facturas hasta completar el registro.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => setState(() => _skipped = false),
                  icon: const Icon(Icons.edit),
                  label: const Text('Registrar mi negocio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_state == BusinessSetupState.requiresSetup) {
      return NegocioSetupPage(
        usuario: widget.usuario,
        businessSetupService: _service,
        onCompleted: _load,
        onSkip: () => setState(() => _skipped = true),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 52),
                const SizedBox(height: 12),
                Text(
                  'No se pudo verificar tu negocio configurado.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
