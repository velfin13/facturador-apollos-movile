import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_links/app_links.dart';
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

enum _StepStatus { pending, active, done }

class _PaymentDialogData {
  final PaymentFlowStage stage;
  final int step; // 0=verificando paypal, 1=activando plan, 2=listo
  final String message;
  final Map<String, dynamic>? subscriptionData;

  const _PaymentDialogData({
    required this.stage,
    required this.step,
    required this.message,
    this.subscriptionData,
  });
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
  bool _isVerifyingSubscription = false;
  String? _pendingPayPalOrderId;
  String? _pendingPayphoneTransactionId;
  String? _pendingPayphoneClientTransactionId;
  String _pendingPaymentGateway = 'PAYPAL';
  String? _processingPlanId;
  double? _pendingPlanMonthly;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _deepLinkSubscription;
  Future<_SubscriptionViewData>? _subscriptionFuture;
  late final ValueNotifier<_PaymentDialogData> _paymentNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinks = AppLinks();
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingUri,
      onError: (_) {},
    );
    _paymentNotifier = ValueNotifier(
      const _PaymentDialogData(
        stage: PaymentFlowStage.idle,
        step: 0,
        message: '',
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    _paymentNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _awaitingSubscriptionCheckout) {
      _verifySubscriptionAfterCheckout();
    }
  }

  void _handleIncomingUri(Uri uri) {
    if (uri.scheme != 'com.apollos.facturador') return;

    if (uri.host == 'subscription-cancel') {
      _awaitingSubscriptionCheckout = false;
      _pendingPayPalOrderId = null;
      _pendingPayphoneTransactionId = null;
      _pendingPayphoneClientTransactionId = null;
      _pendingPaymentGateway = 'PAYPAL';
      if (!mounted) return;
      _updateSubscriptionFlow(
        PaymentFlowStage.error,
        'Pago cancelado por el usuario',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pago cancelado.')));
      return;
    }

    if (uri.host == 'subscription-return') {
      final query = uri.queryParameters;
      final payPalToken = query['token'] ?? query['orderId'];
      if (payPalToken != null && payPalToken.isNotEmpty) {
        _pendingPayPalOrderId = payPalToken;
      }

      final payphoneId = query['id'];
      final payphoneClientTx = query['clientTransactionId'];
      if ((payphoneId ?? '').isNotEmpty &&
          (payphoneClientTx ?? '').isNotEmpty) {
        _pendingPayphoneTransactionId = payphoneId;
        _pendingPayphoneClientTransactionId = payphoneClientTx;
      }

      if (_awaitingSubscriptionCheckout) {
        _verifySubscriptionAfterCheckout();
      }
    }
  }

  List<_NavItem> get _navItems {
    final items = <_NavItem>[];

    items.add(
      _NavItem(
        label: 'Inicio',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        page: DashboardPage(usuario: widget.usuario),
      ),
    );

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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
              ListTile(
                leading: Icon(
                  Icons.security_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Firma digital'),
                subtitle: const Text('Gestionar certificado .p12'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showFirmaDigitalSheet(context);
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
      ),
    );
  }

  void _showFirmaDigitalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FirmaDigitalSheet(),
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
      return (payload['data'] as Map).map((k, v) => MapEntry(k.toString(), v));
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
    final results = await Future.wait([_getCurrentSubscription(), _getPlans()]);

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
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 42,
                      ),
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

              final subscriptionType = (current['subscriptionType'] ?? '')
                  .toString();
              final normalizedSubscriptionType = subscriptionType.toUpperCase();
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Estado: $status'),
                              Text(
                                'Facturas restantes: $remainingInvoices / $invoiceLimit',
                              ),
                              Text('Empresas permitidas: $maxCompanies'),
                            ],
                          ),
                        ),
                      ),
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
                                (plan['precioMensual'] as num?)?.toDouble() ??
                                0;
                            final monthly = planMonthlyValue.toString();
                            final limitInvoices =
                                (plan['limiteFacturasMensual'] ?? 0).toString();
                            final maxComp = (plan['maximoEmpresas'] ?? 0)
                                .toString();
                            final normalizedPlanName = planName.toUpperCase();
                            final normalizedPlanCode = planCode.toUpperCase();
                            final normalizedCurrentPlanId =
                                currentPlanId.isNotEmpty ? currentPlanId : '';
                            final isCurrent =
                                normalizedPlanName ==
                                    normalizedSubscriptionType ||
                                normalizedPlanCode ==
                                    normalizedSubscriptionType ||
                                (normalizedCurrentPlanId.isNotEmpty &&
                                    planId.isNotEmpty &&
                                    planId == normalizedCurrentPlanId);
                            final canUpgradePlan =
                                planMonthlyValue > currentPlanMonthly;
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
                                            visualDensity:
                                                VisualDensity.compact,
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
                                                  : () =>
                                                        _selectGatewayAndUpgrade(
                                                          context,
                                                          plan,
                                                        ),
                                              child: isProcessingThisPlan
                                                  ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: const [
                                                        SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: Colors
                                                                    .white,
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
                        color: Colors.black.withValues(alpha: 0.4),
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

  Future<void> _selectGatewayAndUpgrade(
    BuildContext context,
    Map<String, dynamic> plan,
  ) async {
    final selectedGateway = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Selecciona método de pago',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('PayPal'),
              subtitle: const Text('Pago con cuenta PayPal o tarjeta'),
              onTap: () => Navigator.pop(sheetContext, 'PAYPAL'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android_outlined),
              title: const Text('Payphone'),
              subtitle: const Text('Pago con Payphone'),
              onTap: () => Navigator.pop(sheetContext, 'PAYPHONE'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted || selectedGateway == null) return;
    await _upgradePlan(context, plan, selectedGateway);
  }

  Future<void> _upgradePlan(
    BuildContext context,
    Map<String, dynamic> plan,
    String selectedGateway,
  ) async {
    final planId = (plan['id'] ?? '').toString();
    final planName = (plan['nombre'] ?? '').toString();
    final monthly = (plan['precioMensual'] as num?)?.toDouble() ?? 0;

    if (planId.isEmpty || planName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plan invalido')));
      return;
    }

    setState(() {
      _processingPlanId = planId;
      _pendingPlanMonthly = monthly;
      _pendingPaymentGateway = selectedGateway;
      _pendingPayPalOrderId = null;
      _pendingPayphoneTransactionId = null;
      _pendingPayphoneClientTransactionId = null;
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
          'returnUrl': selectedGateway == 'PAYPHONE'
              ? 'http://192.168.0.106:5117/api/subscriptions/payphone-return'
              : 'com.apollos.facturador://subscription-return',
          'cancelUrl': selectedGateway == 'PAYPHONE'
              ? 'http://192.168.0.106:5117/api/subscriptions/payphone-cancel'
              : 'com.apollos.facturador://subscription-cancel',
          'customerEmail': widget.usuario.email,
          'customerName': widget.usuario.nombre,
          'billingPeriod': 'MENSUAL',
          'paymentGateway': selectedGateway,
        },
      );

      final payload = response.data;
      final data = (payload is Map && payload['data'] is Map)
          ? (payload['data'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};

      final approvalUrl = (data['approvalUrl'] ?? '').toString();
      final status = (data['status'] ?? '').toString();

      if (approvalUrl.isNotEmpty) {
        _updateSubscriptionFlow(
          PaymentFlowStage.awaitingApproval,
          selectedGateway == 'PAYPHONE'
              ? 'Preparando Payphone...'
              : 'Preparando PayPal...',
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

        if (selectedGateway == 'PAYPAL') {
          final token =
              uri.queryParameters['token'] ?? uri.queryParameters['orderId'];
          if (token != null && token.isNotEmpty) {
            _pendingPayPalOrderId = token;
          }
        }

        _awaitingSubscriptionCheckout = true;
        _updateSubscriptionFlow(
          PaymentFlowStage.awaitingApproval,
          selectedGateway == 'PAYPHONE'
              ? 'Abriendo Payphone...'
              : 'Abriendo PayPal...',
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedGateway == 'PAYPHONE'
                  ? 'Abriendo Payphone. Finaliza el pago y vuelve a la aplicación.'
                  : 'Abriendo PayPal. Finaliza el pago y vuelve a la aplicación.',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _processingPlanId = null;
        _pendingPlanMonthly = null;
      });
    } catch (_) {
      if (!context.mounted) return;
      const message = 'No se pudo abrir el navegador';
      _updateSubscriptionFlow(PaymentFlowStage.error, message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(message)));
      setState(() {
        _processingPlanId = null;
        _pendingPlanMonthly = null;
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
          _pendingPlanMonthly = null;
        });
      });
    }
  }

  bool get _isPlanFlowRunning =>
      _subscriptionFlowStage == PaymentFlowStage.creating ||
      _subscriptionFlowStage == PaymentFlowStage.awaitingApproval ||
      _subscriptionFlowStage == PaymentFlowStage.confirming;

  Future<void> _verifySubscriptionAfterCheckout() async {
    if (!_awaitingSubscriptionCheckout || _isVerifyingSubscription) return;

    final gateway = _pendingPaymentGateway.toUpperCase();
    if (gateway == 'PAYPHONE' &&
        ((_pendingPayphoneTransactionId ?? '').isEmpty ||
            (_pendingPayphoneClientTransactionId ?? '').isEmpty)) {
      // Esperar deep link de retorno con id y clientTransactionId.
      return;
    }

    _isVerifyingSubscription = true;
    _awaitingSubscriptionCheckout = false;

    _paymentNotifier.value = _PaymentDialogData(
      stage: PaymentFlowStage.confirming,
      step: 0,
      message: gateway == 'PAYPHONE'
          ? 'Verificando tu pago con Payphone...'
          : 'Verificando tu pago con PayPal...',
    );

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => _PaymentProcessingDialog(notifier: _paymentNotifier),
    );

    try {
      if (gateway == 'PAYPHONE') {
        final transactionId = int.tryParse(_pendingPayphoneTransactionId ?? '');
        final clientTransactionId = _pendingPayphoneClientTransactionId ?? '';
        if (transactionId == null || clientTransactionId.isEmpty) {
          throw Exception('Datos de confirmación Payphone incompletos');
        }
        await getIt<DioClient>().post(
          '/Subscriptions/confirm-payphone',
          data: {
            'transactionId': transactionId,
            'clientTransactionId': clientTransactionId,
          },
        );
      } else if ((_pendingPayPalOrderId ?? '').isNotEmpty) {
        await getIt<DioClient>().post(
          '/Subscriptions/confirm-paypal',
          data: {'orderId': _pendingPayPalOrderId},
        );
      }

      _paymentNotifier.value = const _PaymentDialogData(
        stage: PaymentFlowStage.confirming,
        step: 1,
        message: 'Activando tu suscripción...',
      );

      final current = await _getCurrentSubscription();
      final status = (current['status'] ?? '').toString();
      final isActive = status.toUpperCase().contains('ACTIV');

      final subscriptionData = <String, dynamic>{
        ...current,
        if (_pendingPlanMonthly != null) 'amountCharged': _pendingPlanMonthly,
      };

      _paymentNotifier.value = _PaymentDialogData(
        stage: isActive ? PaymentFlowStage.success : PaymentFlowStage.error,
        step: 2,
        message: isActive
            ? '¡Tu plan ha sido activado exitosamente!'
            : 'El plan no pudo activarse. Estado: $status',
        subscriptionData: isActive ? subscriptionData : null,
      );

      if (!mounted) return;
      setState(() {
        _subscriptionFlowStage = isActive
            ? PaymentFlowStage.success
            : PaymentFlowStage.error;
        _subscriptionFlowMessage = isActive
            ? 'Pago confirmado'
            : 'No se pudo activar el plan';
        _processingPlanId = null;
        _pendingPlanMonthly = null;
      });
    } catch (_) {
      _paymentNotifier.value = const _PaymentDialogData(
        stage: PaymentFlowStage.error,
        step: 2,
        message: 'No se pudo validar el pago con el servidor.',
      );
      if (!mounted) return;
      setState(() {
        _subscriptionFlowStage = PaymentFlowStage.error;
        _subscriptionFlowMessage = 'No se pudo validar el pago';
        _processingPlanId = null;
        _pendingPlanMonthly = null;
      });
    } finally {
      _pendingPayPalOrderId = null;
      _pendingPayphoneTransactionId = null;
      _pendingPayphoneClientTransactionId = null;
      _pendingPaymentGateway = 'PAYPAL';
      _isVerifyingSubscription = false;
    }
  }
}

// ─── Dialog de procesamiento de pago ─────────────────────────────────────────

class _PaymentProcessingDialog extends StatefulWidget {
  final ValueNotifier<_PaymentDialogData> notifier;

  const _PaymentProcessingDialog({required this.notifier});

  @override
  State<_PaymentProcessingDialog> createState() =>
      _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<_PaymentProcessingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    widget.notifier.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    final state = widget.notifier.value;
    if ((state.stage == PaymentFlowStage.success ||
            state.stage == PaymentFlowStage.error) &&
        !_iconController.isAnimating &&
        _iconController.value == 0) {
      _iconController.forward();
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onUpdate);
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.notifier.value;
    final isSuccess = state.stage == PaymentFlowStage.success;
    final isError = state.stage == PaymentFlowStage.error;
    final isDone = isSuccess || isError;

    return PopScope(
      canPop: isDone,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(theme, isSuccess, isError),
              const SizedBox(height: 20),
              Text(
                _titleText(isSuccess, isError),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSuccess
                      ? const Color(0xFF2E7D32)
                      : isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                state.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isDone) ...[
                const SizedBox(height: 28),
                _buildSteps(theme, state.step),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ),
              ],
              if (isSuccess && state.subscriptionData != null) ...[
                const SizedBox(height: 24),
                _buildSuccessCard(theme, state.subscriptionData!),
              ],
              if (isError) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Puedes intentar nuevamente desde la sección de planes.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (isDone) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: isError
                        ? FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                          )
                        : null,
                    child: Text(isSuccess ? 'Continuar' : 'Cerrar'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _titleText(bool isSuccess, bool isError) {
    if (isSuccess) return '¡Suscripción activada!';
    if (isError) return 'Hubo un problema';
    return 'Procesando pago';
  }

  Widget _buildIcon(ThemeData theme, bool isSuccess, bool isError) {
    if (isSuccess) {
      return ScaleTransition(
        scale: _iconScale,
        child: Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2E7D32),
            size: 54,
          ),
        ),
      );
    }

    if (isError) {
      return ScaleTransition(
        scale: _iconScale,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cancel_rounded,
            color: theme.colorScheme.error,
            size: 54,
          ),
        ),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSteps(ThemeData theme, int currentStep) {
    final steps = [
      (label: 'Verificando pago', step: 0),
      (label: 'Activando tu suscripción', step: 1),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((s) {
        final _StepStatus status;
        if (currentStep > s.step) {
          status = _StepStatus.done;
        } else if (currentStep == s.step) {
          status = _StepStatus.active;
        } else {
          status = _StepStatus.pending;
        }
        return _buildStepRow(theme, s.label, status);
      }).toList(),
    );
  }

  Widget _buildStepRow(ThemeData theme, String label, _StepStatus status) {
    final activeColor = theme.colorScheme.primary;
    const doneColor = Color(0xFF2E7D32);
    final pendingColor = theme.colorScheme.outlineVariant;

    final Widget icon;
    final Color textColor;
    final FontWeight fontWeight;

    switch (status) {
      case _StepStatus.active:
        icon = SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: activeColor,
          ),
        );
        textColor = theme.colorScheme.onSurface;
        fontWeight = FontWeight.w600;
      case _StepStatus.done:
        icon = const Icon(
          Icons.check_circle_rounded,
          color: doneColor,
          size: 20,
        );
        textColor = theme.colorScheme.onSurfaceVariant;
        fontWeight = FontWeight.normal;
      case _StepStatus.pending:
        icon = Icon(
          Icons.radio_button_unchecked,
          color: pendingColor,
          size: 20,
        );
        textColor = pendingColor;
        fontWeight = FontWeight.normal;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(width: 20, height: 20, child: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(ThemeData theme, Map<String, dynamic> data) {
    final planName = (data['subscriptionType'] ?? '').toString();
    final invoiceLimit = data['invoiceLimit']?.toString() ?? '0';
    final amountCharged = data['amountCharged'];
    final periodEnd = (data['periodEndDate'] ?? '').toString();

    String formattedDate = '';
    if (periodEnd.isNotEmpty) {
      try {
        final date = DateTime.parse(periodEnd);
        const months = [
          'ene',
          'feb',
          'mar',
          'abr',
          'may',
          'jun',
          'jul',
          'ago',
          'sep',
          'oct',
          'nov',
          'dic',
        ];
        formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';
      } catch (_) {
        formattedDate = periodEnd;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF2E7D32),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  planName.isEmpty ? 'Plan activo' : planName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    fontSize: 15,
                  ),
                ),
              ),
              if (amountCharged != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$$amountCharged/mes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFC8E6C9), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(
                Icons.receipt_long_outlined,
                '$invoiceLimit facturas/mes',
              ),
              const SizedBox(width: 8),
              if (formattedDate.isNotEmpty)
                _infoChip(
                  Icons.calendar_month_outlined,
                  'Hasta: $formattedDate',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF388E3C)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF388E3C),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Firma Digital Sheet ──────────────────────────────────────────────────────

class _FirmaDigitalSheet extends StatefulWidget {
  const _FirmaDigitalSheet();

  @override
  State<_FirmaDigitalSheet> createState() => _FirmaDigitalSheetState();
}

class _FirmaDigitalSheetState extends State<_FirmaDigitalSheet> {
  String? _archivoNombre;
  Uint8List? _archivoBytes;
  final _claveController = TextEditingController();
  bool _claveVisible = false;
  bool _uploading = false;
  String? _certificadoActual;
  DateTime? _vencimiento;
  bool _loadingTenant = true;

  @override
  void initState() {
    super.initState();
    _cargarCertificadoActual();
  }

  @override
  void dispose() {
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _cargarCertificadoActual() async {
    try {
      final response = await getIt<DioClient>().get('/Tenants/current');
      if (response.data is Map && response.data['data'] is Map) {
        final data = response.data['data'] as Map;
        if (mounted) {
          DateTime? venc;
          final vencRaw = data['certificadoVencimiento']?.toString();
          if (vencRaw != null && vencRaw.isNotEmpty) {
            venc = DateTime.tryParse(vencRaw)?.toLocal();
          }
          setState(() {
            _certificadoActual = data['certificadoNombre']?.toString();
            _vencimiento = venc;
            _loadingTenant = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingTenant = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTenant = false);
    }
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['p12'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      final file = result.files.single;
      setState(() {
        _archivoNombre = file.name;
        _archivoBytes = file.bytes;
      });
    }
  }

  Future<void> _subirCertificado() async {
    if (_archivoBytes == null || _archivoNombre == null) {
      _showSnack('Selecciona un archivo .p12 primero');
      return;
    }
    if (_claveController.text.trim().isEmpty) {
      _showSnack('Ingresa la clave del certificado');
      return;
    }

    setState(() => _uploading = true);

    try {
      final formData = FormData.fromMap({
        'certificado': MultipartFile.fromBytes(
          _archivoBytes!,
          filename: _archivoNombre,
        ),
        'clave': _claveController.text.trim(),
      });

      await getIt<DioClient>().post('/Tenants/certificado', data: formData);

      if (mounted) {
        // Recargar tenant para obtener la nueva fecha de vencimiento
        final nombreSubido = _archivoNombre;
        setState(() {
          _certificadoActual = nombreSubido;
          _archivoNombre = null;
          _archivoBytes = null;
          _claveController.clear();
          _uploading = false;
        });
        _showSnack('Certificado subido correctamente', isError: false);
        _cargarCertificadoActual();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        final msg = (e.response?.data is Map)
            ? (e.response!.data['message']?.toString() ??
                  'Error al subir el certificado')
            : 'Error al subir el certificado';
        _showSnack(msg);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploading = false);
        _showSnack('Error inesperado al subir el certificado');
      }
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _tieneCert =>
      _certificadoActual != null && _certificadoActual!.isNotEmpty;

  /// null = sin cert, false = vencido, true = vigente
  bool? get _certVigente {
    if (!_tieneCert || _vencimiento == null) return null;
    return _vencimiento!.isAfter(DateTime.now());
  }

  bool get _certPorVencer {
    if (_vencimiento == null) return false;
    return _certVigente == true &&
        _vencimiento!.difference(DateTime.now()).inDays <= 30;
  }

  String _formatFecha(DateTime d) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${meses[d.month - 1]} ${d.year}';
  }

  Widget _buildCertStatus(ThemeData theme) {
    if (!_tieneCert) {
      return Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            'Sin certificado',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      );
    }

    final expired = _certVigente == false;
    final porVencer = _certPorVencer;
    final iconColor = expired
        ? Colors.red.shade700
        : porVencer
        ? Colors.amber.shade800
        : Colors.green.shade700;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          expired
              ? Icons.cancel_outlined
              : porVencer
              ? Icons.warning_amber_outlined
              : Icons.check_circle_outline,
          color: iconColor,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expired
                    ? 'Certificado vencido'
                    : porVencer
                    ? 'Certificado por vencer'
                    : 'Certificado activo',
                style: TextStyle(fontWeight: FontWeight.w600, color: iconColor),
              ),
              const SizedBox(height: 2),
              Text(
                _certificadoActual!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: iconColor.withValues(alpha: 0.85),
                ),
              ),
              if (_vencimiento != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 13, color: iconColor),
                    const SizedBox(width: 4),
                    Text(
                      'Vence: ${_formatFecha(_vencimiento!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.security_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Firma Digital',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Estado actual del certificado ─────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _loadingTenant
                  ? theme.colorScheme.surfaceContainerLow
                  : !_tieneCert
                  ? Colors.orange.shade50
                  : _certVigente == false
                  ? Colors.red.shade50
                  : _certPorVencer
                  ? Colors.amber.shade50
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _loadingTenant
                    ? theme.colorScheme.outlineVariant
                    : !_tieneCert
                    ? Colors.orange.shade200
                    : _certVigente == false
                    ? Colors.red.shade200
                    : _certPorVencer
                    ? Colors.amber.shade300
                    : Colors.green.shade200,
              ),
            ),
            child: _loadingTenant
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Verificando certificado...'),
                    ],
                  )
                : _buildCertStatus(theme),
          ),
          const SizedBox(height: 16),

          Text(
            _tieneCert ? 'Reemplazar certificado' : 'Subir certificado',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_tieneCert)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Sube un nuevo archivo .p12 para reemplazar el actual.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── Selector de archivo ───────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _uploading ? null : _seleccionarArchivo,
            icon: Icon(
              _archivoBytes != null
                  ? Icons.check_circle_outline
                  : Icons.attach_file,
              size: 20,
            ),
            label: Text(
              _archivoNombre ?? 'Seleccionar archivo .p12',
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 12),

          // ── Campo de clave ─────────────────────────────────────────────────
          TextField(
            controller: _claveController,
            obscureText: !_claveVisible,
            enabled: !_uploading,
            decoration: InputDecoration(
              labelText: _tieneCert
                  ? 'Nueva clave del certificado'
                  : 'Clave del certificado',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _claveVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _claveVisible = !_claveVisible),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Botón subir ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_uploading || _archivoBytes == null)
                  ? null
                  : _subirCertificado,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_tieneCert ? Icons.swap_horiz : Icons.upload_rounded),
              label: Text(
                _uploading
                    ? 'Subiendo...'
                    : _tieneCert
                    ? 'Reemplazar certificado'
                    : 'Subir certificado',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clases auxiliares ────────────────────────────────────────────────────────

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
