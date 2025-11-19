import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cliente.dart';
import '../bloc/cliente_bloc.dart';

class CrearClientePage extends StatefulWidget {
  const CrearClientePage({super.key});

  @override
  State<CrearClientePage> createState() => _CrearClientePageState();
}

class _CrearClientePageState extends State<CrearClientePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _identificacionController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _razonSocialController.dispose();
    _identificacionController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _guardarCliente() {
    if (_formKey.currentState!.validate()) {
      // Generar ID en formato CLI-XXX
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final idNumero = (timestamp % 10000).toString().padLeft(4, '0');

      final cliente = Cliente(
        id: 'CLI-$idNumero',
        periodo: DateTime.now().year.toString(),
        nombre: _nombreController.text.trim(),
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
        ciudad: null,
        tipo: '01', // Tipo por defecto: Cliente Natural
        activo: true,
      );

      context.read<ClienteBloc>().add(CreateClienteEvent(cliente));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Cliente'),
        backgroundColor: Colors.blue,
      ),
      body: BlocListener<ClienteBloc, ClienteState>(
        listener: (context, state) {
          if (state is ClienteCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is ClienteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ClienteBloc, ClienteState>(
          builder: (context, state) {
            final isLoading = state is ClienteCreating;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        hintText: 'Ingrese el nombre del cliente',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Razón Social
                    TextFormField(
                      controller: _razonSocialController,
                      decoration: const InputDecoration(
                        labelText: 'Razón Social',
                        hintText: 'Ingrese la razón social (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Identificación
                    TextFormField(
                      controller: _identificacionController,
                      decoration: const InputDecoration(
                        labelText: 'Identificación *',
                        hintText: 'RUC, CI, Pasaporte',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La identificación es obligatoria';
                        }
                        if (value.trim().length < 10) {
                          return 'La identificación debe tener al menos 10 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'correo@ejemplo.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      enabled: !isLoading,
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
                    const SizedBox(height: 16),

                    // Teléfono
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        hintText: '0991234567',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Dirección
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        hintText: 'Ingrese la dirección',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      enabled: !isLoading,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Nota de campos obligatorios
                    const Text(
                      '* Campos obligatorios',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _guardarCliente,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
