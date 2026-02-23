import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cliente.dart';
import '../bloc/cliente_bloc.dart';

class CrearClientePage extends StatefulWidget {
  final Cliente? cliente;

  const CrearClientePage({super.key, this.cliente});

  @override
  State<CrearClientePage> createState() => _CrearClientePageState();
}

class _CrearClientePageState extends State<CrearClientePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _identificacionController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();

  String _tipoIdentificacion = '01'; // 01 = Natural, 02 = Jurídico

  static const _tipos = [
    _TipoItem('01', 'Persona Natural', Icons.person_outline),
    _TipoItem('02', 'Persona Jurídica', Icons.business_outlined),
  ];

  bool get _isEditing => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _nombreController.text = c.nombre;
      _identificacionController.text = c.ruc;
      _emailController.text = c.email ?? '';
      _telefonoController.text = c.telefono ?? '';
      _direccionController.text = c.direccion ?? '';
      _ciudadController.text = c.ciudad ?? '';
      _tipoIdentificacion = c.tipo ?? '01';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _identificacionController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  void _guardarCliente() {
    if (!_formKey.currentState!.validate()) return;

    final cliente = Cliente(
      id: widget.cliente?.id ?? '',
      periodo: widget.cliente?.periodo ?? '',
      nombre: _nombreController.text.trim().toUpperCase(),
      ruc: _identificacionController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      ciudad: _ciudadController.text.trim().isEmpty
          ? null
          : _ciudadController.text.trim().toUpperCase(),
      tipo: _tipoIdentificacion,
      activo: widget.cliente?.activo ?? true,
    );

    if (_isEditing) {
      context.read<ClienteBloc>().add(UpdateClienteEvent(cliente));
    } else {
      context.read<ClienteBloc>().add(CreateClienteEvent(cliente));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ClienteBloc, ClienteState>(
      listener: (context, state) {
        if (state is ClienteCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cliente creado exitosamente'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is ClienteUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cliente actualizado exitosamente'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is ClienteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Hero header ──────────────────────────────────────
                      _buildHeroHeader(theme),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        child: Column(
                          children: [
                            // ── Tipo de persona ────────────────────────────
                            _buildTipoSelector(theme),
                            const SizedBox(height: 16),

                            // ── Identificación ─────────────────────────────
                            _buildSectionCard(
                              title: 'Identificación',
                              icon: Icons.badge_outlined,
                              children: [
                                TextFormField(
                                  controller: _identificacionController,
                                  decoration: const InputDecoration(
                                    labelText: 'RUC / Cédula *',
                                    hintText: '0991234567001',
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'La identificación es obligatoria';
                                    }
                                    if (value.trim().length < 10) {
                                      return 'Debe tener al menos 10 dígitos';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _nombreController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre / Razón social *',
                                    hintText: 'Ej: JUAN CARLOS PÉREZ',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El nombre es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Contacto ───────────────────────────────────
                            _buildSectionCard(
                              title: 'Contacto',
                              icon: Icons.contact_phone_outlined,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'correo@ejemplo.com',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value != null &&
                                        value.trim().isNotEmpty &&
                                        !value.contains('@')) {
                                      return 'Ingrese un email válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _telefonoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono',
                                    hintText: '0991234567',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d\s\+\-\(\)]'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Ubicación ──────────────────────────────────
                            _buildSectionCard(
                              title: 'Ubicación',
                              icon: Icons.location_on_outlined,
                              children: [
                                TextFormField(
                                  controller: _ciudadController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ciudad',
                                    hintText: 'Ej: GUAYAQUIL',
                                    prefixIcon:
                                        Icon(Icons.location_city_outlined),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _direccionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Dirección',
                                    hintText: 'Calle principal y secundaria',
                                    prefixIcon: Icon(Icons.map_outlined),
                                  ),
                                  maxLines: 2,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero header ─────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(ThemeData theme) {
    final nombre = _nombreController.text.trim();
    final ruc = _identificacionController.text.trim();
    final initial =
        nombre.isNotEmpty ? nombre[0].toUpperCase() : (_isEditing ? '?' : '+');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar con iniciales
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Nombre + RUC
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.isNotEmpty
                      ? nombre
                      : (_isEditing
                          ? widget.cliente!.nombre
                          : 'Nuevo cliente'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (ruc.isNotEmpty)
                      _HeaderBadge(
                        label: ruc.length > 11
                            ? 'RUC: $ruc'
                            : 'CI: $ruc',
                        icon: Icons.badge,
                      ),
                    if (ruc.isNotEmpty) const SizedBox(width: 6),
                    _HeaderBadge(
                      label: _tipoIdentificacion == '01'
                          ? 'Natural'
                          : 'Jurídica',
                      icon: _tipoIdentificacion == '01'
                          ? Icons.person
                          : Icons.business,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de tipo persona ─────────────────────────────────────────────────
  Widget _buildTipoSelector(ThemeData theme) {
    return Row(
      children: _tipos.map((tipo) {
        final selected = _tipoIdentificacion == tipo.value;
        final color = theme.colorScheme.primary;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: tipo == _tipos.first ? 8 : 0,
              left: tipo == _tipos.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _tipoIdentificacion = tipo.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? color
                        : theme.colorScheme.outlineVariant,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      tipo.icon,
                      color: selected ? color : theme.colorScheme.outline,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tipo.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: selected
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Section card ─────────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Botones de acción ────────────────────────────────────────────────────────
  Widget _buildBottomActions(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BlocBuilder<ClienteBloc, ClienteState>(
        builder: (context, state) {
          final isSaving =
              state is ClienteCreating || state is ClienteUpdating;
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : _guardarCliente,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isEditing ? Icons.save : Icons.person_add,
                        ),
                  label: Text(
                    isSaving
                        ? (_isEditing ? 'Actualizando...' : 'Guardando...')
                        : (_isEditing ? 'Actualizar cliente' : 'Guardar cliente'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TipoItem {
  final String value;
  final String label;
  final IconData icon;
  const _TipoItem(this.value, this.label, this.icon);
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _HeaderBadge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
