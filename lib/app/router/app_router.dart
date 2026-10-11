import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/session/user_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pos_dialog.dart';
import '../../features/auth/domain/entities/login_module.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/sales/cart/domain/entities/cart.dart';
import '../../features/sales/cart/presentation/screens/sales_screen.dart';
import '../../features/sales/cart/presentation/screens/weight_screen.dart';
import '../../features/sales/cash_lift/presentation/screens/cash_lift_screen.dart';
import '../../features/sales/discount/presentation/screens/discount_screen.dart';
import '../../features/sales/hold_recall/presentation/screens/hold_recall_screen.dart';
import '../../features/sales/more_functions/presentation/screens/more_functions_screen.dart';
import '../../features/sales/no_sale/presentation/screens/no_sale_screen.dart';
import '../../features/sales/payment/presentation/screens/other_payment_screen.dart';
import '../../features/sales/payout/presentation/screens/payout_screen.dart';
import '../../features/sales/price_check/presentation/screens/price_check_screen.dart';
import '../../features/sales/shift_end/presentation/screens/drawer_float_screen.dart';
import '../../features/sales/shift_end/presentation/screens/shift_end_screen.dart';
import '../../features/sales/transactions/presentation/screens/transactions_screen.dart';
import '../../features/sales/void/domain/repositories/void_repository.dart';
import '../../features/sales/void/presentation/screens/void_reason_screen.dart';
import '../di/injector.dart';
import 'not_ported_screen.dart';
import 'routes.dart';

/// Where each login module goes once the user is signed in.
String _moduleHome(LoginModule module) => switch (module) {
  LoginModule.sales => Routes.sales,
  LoginModule.backOffice => Routes.backOffice,
  LoginModule.products => Routes.productManagement,
  LoginModule.reports => Routes.quickReport,
  LoginModule.settings => Routes.settings,
};

GoRoute _dialog(String path, Widget Function(GoRouterState state) build, {List<RouteBase> routes = const []}) => GoRoute(
  path: path,
  pageBuilder: (_, state) => DialogPage(key: state.pageKey, child: build(state)),
  routes: routes,
);

/// Screens designed in the canvas but not built yet.
const _notPorted = <(String, String, String)>[
  (Routes.productManagement, 'Product Management', 'ProductMgt.dc.html'),
  (Routes.suppliers, 'Suppliers', 'Suppliers.dc.html'),
  (Routes.staffActivity, 'Staff Activity', 'StaffActivity.dc.html'),
  (Routes.quickReport, 'Quick Report', 'QuickReport.dc.html'),
  (Routes.backOffice, 'Back Office', 'BackOffice.dc.html'),
  (Routes.settings, 'Settings', 'Settings.dc.html'),
];

final appRouter = GoRouter(
  initialLocation: Routes.home,
  // Checked on every navigation; signing out then navigating needs no refresh.
  redirect: (context, state) {
    final session = getIt<SessionHolder>().value;
    final path = state.matchedLocation;
    if (path.startsWith(Routes.sales) && session?.logId == null) return Routes.loginFor(LoginModule.sales.slug);
    return null;
  },
  routes: [
    GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: Routes.login,
      builder: (_, state) => LoginScreen(
        module: LoginModule.fromSlug(state.pathParameters['module']),
        onSuccess: (context, module) => context.go(_moduleHome(module)),
      ),
    ),
    GoRoute(
      path: Routes.sales,
      builder: (_, _) => const SalesScreen(),
      routes: [
        _dialog('void', (s) => VoidReasonScreen(request: s.extra! as VoidRequest)),
        _dialog('no-sale', (_) => const NoSaleScreen()),
        _dialog('hold-recall', (s) => HoldRecallScreen(cart: s.extra as Cart? ?? Cart.empty)),
        _dialog('price-check', (s) => PriceCheckScreen(initialQuery: s.extra as String? ?? '')),
        _dialog('other-payment', (s) => OtherPaymentScreen(cart: s.extra! as Cart)),
        _dialog('drawer-float', (_) => const DrawerFloatScreen()),
        _dialog('transactions', (_) => const TransactionsScreen()),
        _dialog('discount', (s) {
          final (cart, wholeSale) = s.extra! as (Cart, bool);
          return DiscountScreen(cart: cart, wholeSale: wholeSale);
        }),
        _dialog('payout', (_) => const PayoutScreen()),
        _dialog('weight', (_) => const WeightScreen()),
        _dialog('more-functions', (_) => const MoreFunctionsScreen(), routes: [_dialog('cash-lift', (_) => const CashLiftScreen())]),
        GoRoute(
          path: 'shift-end',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              backgroundColor: AppColors.scrim,
              body: ShiftEndScreen(
                drawerFloatCents: state.extra as int? ?? 0,
                onDone: () {
                  getIt<SessionHolder>().signOut();
                  context.go(Routes.home);
                },
              ),
            ),
          ),
        ),
      ],
    ),
    for (final (path, title, design) in _notPorted)
      GoRoute(path: path, builder: (_, _) => NotPortedScreen(title: title, design: design)),
  ],
);
