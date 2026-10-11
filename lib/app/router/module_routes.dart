import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/session/access_rights.dart';
import '../../core/session/user_session.dart';
import '../../features/product_management/adjust_stock/presentation/widgets/adjust_stock_panel.dart';
import '../../features/product_management/hub/presentation/screens/product_management_screen.dart';
import '../../features/product_management/non_barcode/presentation/widgets/non_barcode_panel.dart';
import '../../features/product_management/payout_items/presentation/widgets/payout_items_panel.dart';
import '../../features/product_management/price_change/presentation/widgets/price_change_panel.dart';
import '../../features/product_management/weight_items/presentation/widgets/weight_items_panel.dart';
import '../../features/reports/exceptions/presentation/screens/exceptions_screen.dart';
import '../../features/reports/expired_items/presentation/screens/expired_items_screen.dart';
import '../../features/reports/quick_report/presentation/screens/quick_report_screen.dart';
import '../../features/reports/shift_report/presentation/screens/shift_report_screen.dart';
import '../di/injector.dart';
import 'routes.dart';

/// Leaving a module signs the user out, as logging in was for that module.
void _leaveModule(BuildContext context) {
  getIt<SessionHolder>().signOut();
  context.go(Routes.home);
}

const _productTools = <ProductTool>[
  ProductTool(
    name: 'Manage Non-Barcode Products',
    title: 'Add New Non Barcode Item',
    note: 'Shown as quick items on the sales screen',
    icon: Icons.view_list_rounded,
    ink: Color(0xFF2952A3),
    fill: Color(0xFFE8EEFB),
    accessFlag: 'manageNonBarcodeProductsAccess',
    builder: _nonBarcode,
  ),
  ProductTool(
    name: 'Add Weight Products',
    title: 'Add New Weight Item',
    note: 'Price per kg, sold from the Weight key on the till',
    icon: Icons.scale_outlined,
    ink: Color(0xFF0B7A55),
    fill: Color(0xFFE3F5EE),
    accessFlag: 'addWeightProductsAccess',
    builder: _weight,
  ),
  ProductTool(
    name: 'Manage Payout Products',
    title: 'Add New Payout',
    note: 'Reasons shown on the Payout screen',
    icon: Icons.outbox_outlined,
    ink: Color(0xFF9A5B00),
    fill: Color(0xFFFFF3DC),
    accessFlag: 'managePayoutProductAccess',
    builder: _payout,
  ),
  ProductTool(
    name: 'Adjust Stock',
    title: 'Stock Adjustment',
    note: 'Please scan barcode and tap Find to load data',
    icon: Icons.inventory_2_outlined,
    ink: Color(0xFF5B3FB0),
    fill: Color(0xFFEFEAFB),
    accessFlag: 'adjustStockAccess',
    builder: _adjustStock,
  ),
  ProductTool(
    name: 'Price Change',
    title: 'Price Change',
    note: 'Update a price or record an expiry date',
    icon: Icons.sell_outlined,
    ink: Color(0xFFB4233C),
    fill: Color(0xFFFDECEE),
    accessFlag: AccessRights.priceUpdate,
    builder: _priceChange,
  ),
  ProductTool(
    name: 'Quick Label',
    title: 'Quick Label',
    note: 'Label printing is not set up yet.',
    icon: Icons.label_outline_rounded,
    ink: Color(0xFF0B6E6E),
    fill: Color(0xFFDFF3F3),
    accessFlag: 'quickLabelAccess',
  ),
];

Widget _nonBarcode(BuildContext _) => const NonBarcodePanel();
Widget _weight(BuildContext _) => const WeightItemsPanel();
Widget _payout(BuildContext _) => const PayoutItemsPanel();
Widget _adjustStock(BuildContext _) => const AdjustStockPanel();
Widget _priceChange(BuildContext _) => const PriceChangePanel();

final productRoutes = <RouteBase>[
  GoRoute(
    path: Routes.productManagement,
    builder: (context, _) => ProductManagementScreen(tools: _productTools, onBack: () => _leaveModule(context)),
  ),
];

final reportRoutes = <RouteBase>[
  GoRoute(
    path: Routes.quickReport,
    builder: (context, _) => QuickReportScreen(
      onBack: () => _leaveModule(context),
      links: [
        ReportLink('Live Shift Report', 'The shift that is open now', Icons.schedule_rounded, const Color(0xFF0B7A55), const Color(0xFFE3F5EE),
            'liveShiftReportAccess', () => context.go(Routes.shiftReport)),
        ReportLink('All Shift Report', 'Any past shift by date, user and shift', Icons.bar_chart_rounded, const Color(0xFF2952A3),
            const Color(0xFFE8EEFB), 'allShiftReportAccess', () => context.go('${Routes.shiftReport}?all=1')),
        ReportLink('Exceptions', 'Voids, no sales, refunds and age refusals', Icons.warning_amber_rounded, const Color(0xFFB4233C),
            const Color(0xFFFDECEE), 'exceptionsAccess', () => context.go(Routes.exceptions)),
        ReportLink('Expired Items', 'Products past their expiry date', Icons.event_busy_outlined, const Color(0xFF9A5B00), const Color(0xFFFFF3DC),
            'expiredItemsAccess', () => context.go(Routes.expiredItems)),
      ],
    ),
  ),
  GoRoute(
    path: Routes.shiftReport,
    builder: (context, state) => ShiftReportScreen(
      key: ValueKey(state.uri.queryParameters['all']),
      allShifts: state.uri.queryParameters['all'] == '1',
      onBack: () => context.go(Routes.quickReport),
    ),
  ),
  GoRoute(path: Routes.exceptions, builder: (context, _) => ExceptionsScreen(onBack: () => context.go(Routes.quickReport))),
  GoRoute(path: Routes.expiredItems, builder: (context, _) => ExpiredItemsScreen(onBack: () => context.go(Routes.quickReport))),
];
