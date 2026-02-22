import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/entities/usuario.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection/injection_container.dart';
import '../../../clientes/presentation/pages/clientes_page.dart';
import '../../../clientes/presentation/bloc/cliente_bloc.dart';
import '../../../productos/presentation/pages/productos_page.dart';
import '../../../productos/presentation/bloc/producto_bloc.dart';
import '../../../facturacion/presentation/pages/facturas_page.dart';
import '../../../facturacion/presentation/pages/crear_factura_page.dart';
import 'dashboard_page.dart';
import 'package:url_launcher/url_launcher.dart';

enum PaymentFlowStage {
  idle,
  creating,
  awaitingApproval,
  confirming,
  success,
  error,
}

class HomePage extends StatefulWidget {
  final Usuario usuario;

  const HomePage({super.key, required this.usuario});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  PaymentFlowStage _subscriptionFlowStage = PaymentFlowStage.idle;
  String _subscriptionFlowMessage = '';
  bool _awaitingSubscriptionCheckout = false;
  String? _pendingPayPalOrderId;
  String? _processingPlanId;
  Future<_SubscriptionViewData>? _subscriptionFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _awaitingSubscriptionCheckout) {
      _verifySubscriptionAfterCheckout();
    }
  }

  List<_NavItem> get _navItems {
    final items = <_NavItem>[];

    // Dashboard - todos los roles
    items.add(
      _NavItem(
        label: 'Inicio',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        page: DashboardPage(usuario: widget.usuario),
      ),
    );

    // Facturas - admin y cliente
    if (widget.usuario.esAdmin || widget.usuario.esCliente) {
      items.add(
        const _NavItem(
          label: 'Facturas',
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long,
          page: FacturasPage(),
        ),
      );
    }

    // Nueva Factura - admin y cliente
    if (widget.usuario.esAdmin || widget.usuario.esCliente) {
      items.add(
        _NavItem(
          label: 'Facturar',
          icon: Icons.add_circle_outline,
          activeIcon: Icons.add_circle,
          page: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<ClienteBloc>()),
              BlocProvider(create: (_) => getIt<ProductoBloc>()),
            ],
            child: const CrearFacturaPage(),
          ),
        ),
      );
    }

    // Clientes - admin y cliente
    if (widget.usuario.esAdmin || widget.usuario.esCliente) {
      items.add(
        const _NavItem(
          label: 'Clientes',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          page: ClientesPage(),
        ),
      );
    }

    // Productos - admin y cliente
    if (widget.usuario.esAdmin || widget.usuario.esCliente) {
      items.add(
        const _NavItem(
          label: 'Productos',
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          page: ProductosPage(),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _navItems;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(items[_currentIndex].label),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showProfileSheet(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: items.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: items.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    final theme = Theme.of(context);
    final rolActivo = widget.usuario.rolActivo!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                widget.usuario.nombre.isNotEmpty
                    ? widget.usuario.nombre[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.usuario.nombre,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.usuario.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: rolActivo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rolActivo.displayName,
                style: TextStyle(
                  color: rolActivo.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.workspace_premium_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Plan y suscripcion'),
              subtitle: const Text('Ver plan actual y actualizar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showSubscriptionSheet(context);
              },
            ),
            const Divider(),
            if (widget.usuario.tieneMultiplesRoles) ...[
              ListTile(
                leading: Icon(
                  Icons.swap_horiz,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Cambiar rol'),
                subtitle: Text(
                  'Roles disponibles: ${widget.usuario.roles.length}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showRoleSwitcher(context);
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                'Cerrar sesion',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Seleccionar rol',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige el rol con el que deseas continuar trabajando.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ...widget.usuario.rolesOrdenados.map((rol) {
              final isActive = rol == widget.usuario.rolActivo;
              final color = rol.color;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isActive
                        ? BorderSide(color: color, width: 2)
                        : BorderSide.none,
                  ),
                  tileColor: isActive
                      ? color.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(rol.icon, color: color),
                  ),
                  title: Text(
                    rol.displayName,
                    style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isActive
                      ? Icon(Icons.check_circle, color: color)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    Navigator.pop(context);
                    if (!isActive) {
                      context.read<AuthBloc>().add(SwitchRoleEvent(rol));
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text('Estas seguro de que deseas cerrar sesion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getCurrentSubscription() async {
    final response = await getIt<DioClient>().get('/Subscriptions/current');
    final payload = response.data;
    if (payload is Map && payload['data'] is Map) {
      return (payload['data'] as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
    return const {};
  }

  Future<List<Map<String, dynamic>>> _getPlans() async {
    final response = await getIt<DioClient>().get('/Plans');
    final payload = response.data;
    if (payload is Map && payload['data'] is List) {
      return (payload['data'] as List)
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    return const [];
  }

  Future<_SubscriptionViewData> _loadSubscriptionData() async {
    final results = await Future.wait([
      _getCurrentSubscription(),
      _getPlans(),
    ]);

    return _SubscriptionViewData(
      current: results[0] as Map<String, dynamic>,
      plans: results[1] as List<Map<String, dynamic>>,
    );
  }

  void _showSubscriptionSheet(BuildContext context) {
    final theme = Theme.of(context);
    _subscriptionFuture = _loadSubscriptionData();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: FutureBuilder<_SubscriptionViewData>(
            future: _subscriptionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return SizedBox(
                  height: 280,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 42),
                      const SizedBox(height: 12),
                      const Text('No se pudo cargar la suscripcion'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSubscriptionSheet(context);
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!;
              final current = data.current;
              final plans = data.plans;

              final subscriptionType =
                  (current['subscriptionType'] ?? '').toString();
              final normalizedSubscriptionType =
                  subscriptionType.toUpperCase();
              final currentPlanId = (current['planId'] ?? '').toString();
              double currentPlanMonthly = 0;
              if (currentPlanId.isNotEmpty) {
                for (final plan in plans) {
                  final planId = (plan['id'] ?? '').toString();
                  if (planId.isNotEmpty && planId == currentPlanId) {
                    currentPlanMonthly =
                        (plan['precioMensual'] as num?)?.toDouble() ?? 0;
                    break;
                  }
                }
              }
              if (currentPlanMonthly == 0 &&
                  normalizedSubscriptionType.isNotEmpty) {
                for (final plan in plans) {
                  final planName = (plan['nombre'] ?? '').toString();
                  final planCode = (plan['codigo'] ?? '').toString();
                  if (planName.toUpperCase() == normalizedSubscriptionType ||
                      planCode.toUpperCase() == normalizedSubscriptionType) {
                    currentPlanMonthly =
                        (plan['precioMensual'] as num?)?.toDouble() ?? 0;
                    break;
                  }
                }
              }
              final status = (current['status'] ?? '').toString();
              final invoiceLimit = current['invoiceLimit']?.toString() ?? '0';
              final remainingInvoices =
                  current['remainingInvoices']?.toString() ?? '0';
              final maxCompanies =
                  ((current['features'] is Map)
                          ? (current['features']['maxCompanies'])
                          : null)
                      ?.toString() ??
                  '-';
              final showFlowStatus = _subscriptionFlowStage != PaymentFlowStage.idle;

              return Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Plan y suscripcion',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plan actual: ${subscriptionType.isEmpty ? 'Sin plan' : subscriptionType}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text('Estado: $status'),
                              Text('Facturas restantes: $remainingInvoices / $invoiceLimit'),
                              Text('Empresas permitidas: $maxCompanies'),
                            ],
                          ),
                        ),
                      ),
                      if (showFlowStatus) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _subscriptionFlowMessage,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _progressForStage(_subscriptionFlowStage),
                                color: theme.colorScheme.onPrimaryContainer,
                                backgroundColor: theme.colorScheme.onPrimaryContainer.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Actualizar plan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: plans.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            final planName = (plan['nombre'] ?? '').toString();
                            final planCode = (plan['codigo'] ?? '').toString();
                            final planId = (plan['id'] ?? '').toString();
                            final planMonthlyValue =
                                (plan['precioMensual'] as num?)?.toDouble() ?? 0;
                            final monthly = planMonthlyValue.toString();
                            final limitInvoices =
                                (plan['limiteFacturasMensual'] ?? 0).toString();
                            final maxComp =
                                (plan['maximoEmpresas'] ?? 0).toString();
                            final normalizedPlanName = planName.toUpperCase();
                            final normalizedPlanCode = planCode.toUpperCase();
                            final normalizedCurrentPlanId =
                                currentPlanId.isNotEmpty ? currentPlanId : '';
                            final isCurrent = normalizedPlanName ==
                                    normalizedSubscriptionType ||
                                normalizedPlanCode == normalizedSubscriptionType ||
                                (normalizedCurrentPlanId.isNotEmpty &&
                                    planId.isNotEmpty &&
                                    planId == normalizedCurrentPlanId);
                            final canUpgradePlan = planMonthlyValue > currentPlanMonthly;
                            final isProcessingThisPlan =
                                _processingPlanId != null &&
                                    _processingPlanId == planId &&
                                    _isPlanFlowRunning;

                            return Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            planName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (isCurrent)
                                          Chip(
                                            label: const Text('Actual'),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('\$$monthly/mes'),
                                    Text('Facturas/mes: $limitInvoices'),
                                    Text('Empresas: $maxComp'),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: (!isCurrent && canUpgradePlan)
                                          ? FilledButton.tonal(
                                              onPressed: _isPlanFlowRunning
                                                  ? null
                                                  : () => _upgradePlan(context, plan),
                                              child: isProcessingThisPlan
                                                  ? Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Procesando...'),
                                                      ],
                                                    )
                                                  : const Text(
                                                      'Actualizar a este plan',
                                                    ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_isPlanFlowRunning)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _subscriptionFlowMessage,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _upgradePlan(
    BuildContext context,
    Map<String, dynamic> plan,
  ) async {
    final planId = (plan['id'] ?? '').toString();
    final planName = (plan['nombre'] ?? '').toString();
    final monthly = (plan['precioMensual'] as num?)?.toDouble() ?? 0;

    if (planId.isEmpty || planName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan invalido')),
      );
      return;
    }

    setState(() {
      _processingPlanId = planId;
    });
    _updateSubscriptionFlow(
      PaymentFlowStage.creating,
      'Creando suscripción...',
    );

    try {
      final response = await getIt<DioClient>().post(
        '/Subscriptions/create',
        data: {
          'planId': planId,
          'planName': planName,
          'amount': monthly,
          'currency': 'USD',
          'description': 'Suscripcion $planName',
          'returnUrl': 'com.apollos.facturador://subscription-return',
          'cancelUrl': 'com.apollos.facturador://subscription-cancel',
          'customerEmail': widget.usuario.email,
          'customerName': widget.usuario.nombre,
          'billingPeriod': 'MENSUAL',
        },
      );

      final payload = response.data;
      final data =
          (payload is Map && payload['data'] is Map)
          ? (payload['data'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};

      final approvalUrl = (data['approvalUrl'] ?? '').toString();
      final status = (data['status'] ?? '').toString();

      if (approvalUrl.isNotEmpty) {
        _updateSubscriptionFlow(
          PaymentFlowStage.awaitingApproval,
          'Preparando PayPal...',
        );
        final uri = Uri.tryParse(approvalUrl);
        if (uri == null) {
          throw Exception('URL de pago invalida');
        }

        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw Exception('No se pudo abrir el navegador');
        }

        final token = uri.queryParameters['token'] ?? uri.queryParameters['orderId'];
        if (token != null && token.isNotEmpty) {
          _pendingPayPalOrderId = token;
        }

        _awaitingSubscriptionCheckout = true;
        _updateSubscriptionFlow(
          PaymentFlowStage.awaitingApproval,
          'Abriendo PayPal...',
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Abriendo PayPal. Finaliza el pago y vuelve a la aplicación.',
            ),
          ),
        );
      } else {
        if (!context.mounted) return;
        _updateSubscriptionFlow(
          PaymentFlowStage.success,
          'Suscripción creada correctamente',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suscripcion creada. Estado: $status')),
        );
      }
    } on DioException catch (e) {
      final payload = e.response?.data;
      final message = payload is Map
          ? (payload['message']?.toString() ?? 'No se pudo actualizar el plan')
          : 'No se pudo actualizar el plan';
      if (!context.mounted) return;
      _updateSubscriptionFlow(PaymentFlowStage.error, message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {
        _processingPlanId = null;
      });
    } catch (_) {
      if (!context.mounted) return;
      const message = 'No se pudo abrir el navegador';
      _updateSubscriptionFlow(
        PaymentFlowStage.error,
        message,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(message)),
      );
      setState(() {
        _processingPlanId = null;
      });
    }
  }

  void _updateSubscriptionFlow(PaymentFlowStage stage, String message) {
    setState(() {
      _subscriptionFlowStage = stage;
      _subscriptionFlowMessage = message;
    });

    if (stage == PaymentFlowStage.success || stage == PaymentFlowStage.error) {
      Future<void>.delayed(const Duration(seconds: 3)).then((_) {
        if (!mounted) return;
        setState(() {
          _subscriptionFlowStage = PaymentFlowStage.idle;
          _subscriptionFlowMessage = '';
          _processingPlanId = null;
        });
      });
    }
  }

  double _progressForStage(PaymentFlowStage stage) {
    switch (stage) {
      case PaymentFlowStage.creating:
        return 0.25;
      case PaymentFlowStage.awaitingApproval:
        return 0.5;
      case PaymentFlowStage.confirming:
        return 0.75;
      case PaymentFlowStage.success:
        return 1;
      case PaymentFlowStage.error:
        return 1;
      case PaymentFlowStage.idle:
      default:
        return 0;
    }
  }

  bool get _isPlanFlowRunning =>
      _subscriptionFlowStage == PaymentFlowStage.creating ||
      _subscriptionFlowStage == PaymentFlowStage.awaitingApproval ||
      _subscriptionFlowStage == PaymentFlowStage.confirming;

  Future<void> _verifySubscriptionAfterCheckout() async {
    if (!_awaitingSubscriptionCheckout) return;
    _awaitingSubscriptionCheckout = false;
    _updateSubscriptionFlow(
      PaymentFlowStage.confirming,
      'Validando el pago...',
    );

    try {
      if ((_pendingPayPalOrderId ?? '').isNotEmpty) {
        await getIt<DioClient>().post(
          '/Subscriptions/confirm-paypal',
          data: {'orderId': _pendingPayPalOrderId},
        );
      }
      final current = await _getCurrentSubscription();
      final status = (current['status'] ?? '').toString();
      final plan = (current['subscriptionType'] ?? '').toString();
      final isActive = status.toUpperCase().contains('ACTIV');
      final messageSource = isActive
          ? 'Pago confirmado. Plan activo: ${plan.isEmpty ? 'N/D' : plan}'
          : 'No se pudo activar el plan. Estado: $status';

      if (!mounted) return;
      _updateSubscriptionFlow(
        isActive ? PaymentFlowStage.success : PaymentFlowStage.error,
        messageSource,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageSource)),
      );
    } catch (_) {
      if (!mounted) return;
      _updateSubscriptionFlow(
        PaymentFlowStage.error,
        'No se pudo validar el pago',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo validar el pago al regresar'),
        ),
      );
    } finally {
      _pendingPayPalOrderId = null;
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}

class _SubscriptionViewData {
  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> plans;

  const _SubscriptionViewData({required this.current, required this.plans});
}
