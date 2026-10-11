import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/session/access_rights.dart';
import '../../core/session/user_session.dart';
import '../../features/back_office/barcode_products/presentation/screens/barcode_products_screen.dart';
import '../../features/back_office/dashboard/presentation/screens/back_office_screen.dart';
import '../../features/back_office/departments/presentation/screens/departments_screen.dart';
import '../../features/back_office/payment_types/presentation/screens/payment_types_screen.dart';
import '../../features/back_office/role_access/presentation/screens/role_access_screen.dart';
import '../../features/back_office/stock_manager/presentation/screens/stock_manager_screen.dart';
import '../../features/back_office/users/presentation/screens/users_screen.dart';
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
import 'not_ported_screen.dart';
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

const _backOfficeGroups = <BackOfficeGroup>[
  BackOfficeGroup('MANAGEMENT', Color(0xFF2952A3), Color(0xFFE8EEFB), [
    BackOfficeTile('Department Manager', Icons.grid_view_rounded, Routes.departments, 'departmentManagerAccess'),
    BackOfficeTile('User Manager', Icons.person_outline_rounded, Routes.users, 'userManagerAccess'),
    BackOfficeTile('Payment Type Manager', Icons.credit_card_rounded, Routes.paymentTypes, 'paymentTypeManagerAccess'),
    BackOfficeTile('Role Access Manager', Icons.lock_outline_rounded, Routes.roleAccess, 'roleAccessManagerAccess'),
  ]),
  BackOfficeGroup('INVENTORY CONTROL', Color(0xFF0B7A55), Color(0xFFE3F5EE), [
    BackOfficeTile('Sales Manager', Icons.history_rounded, Routes.salesManager, 'salesManagerAccess'),
    BackOfficeTile('Stock Manager', Icons.inventory_2_outlined, Routes.stockManager, 'stockManagerAccess'),
    BackOfficeTile('Product Manager', Icons.sell_outlined, Routes.barcodeProducts, AccessRights.productManager),
    BackOfficeTile('Label Printer', Icons.label_outline_rounded, Routes.labelPrinter, 'labelPrinterAccess'),
  ]),
  BackOfficeGroup('PROMOTION', Color(0xFF9A5B00), Color(0xFFFFF3DC), [
    BackOfficeTile('Promotion Manager', Icons.star_outline_rounded, Routes.promotions, 'promotionManagerAccess'),
    BackOfficeTile('Restore Promotions', Icons.restore_rounded, Routes.promotions, 'restorePromotionAccess'),
  ]),
  BackOfficeGroup('REPORT', Color(0xFF5B3FB0), Color(0xFFEFEAFB), [
    BackOfficeTile('Stock Movement', Icons.bar_chart_rounded, Routes.boReports, 'stockMovementReportAccess'),
    BackOfficeTile('Sale', Icons.show_chart_rounded, Routes.boReports, 'saleReportAccess'),
    BackOfficeTile('Stock Adjustment', Icons.tune_rounded, Routes.boReports, 'stockAdjustmentReportAccess'),
  ]),
];

/// Back Office screens not built yet, with the design each follows.
const _backOfficeNotPorted = <(String, String, String)>[
  (Routes.salesManager, 'Sales Manager', 'BOSalesManager.dc.html'),
  (Routes.labelPrinter, 'Label Printer', 'BOLabelPrinter.dc.html'),
  (Routes.promotions, 'Promotion Manager', 'BOPromotions.dc.html'),
  (Routes.boReports, 'Back Office Reports', 'BOReports.dc.html'),
];

final backOfficeRoutes = <RouteBase>[
  GoRoute(path: Routes.backOffice, builder: (context, _) => BackOfficeScreen(groups: _backOfficeGroups, onClose: () => _leaveModule(context))),
  GoRoute(path: Routes.departments, builder: (context, _) => DepartmentsScreen(onBack: () => context.go(Routes.backOffice))),
  GoRoute(
    path: Routes.users,
    builder: (context, _) => UsersScreen(onBack: () => context.go(Routes.backOffice), onOpenRoleAccess: () => context.go(Routes.roleAccess)),
  ),
  GoRoute(path: Routes.paymentTypes, builder: (context, _) => PaymentTypesScreen(onBack: () => context.go(Routes.backOffice))),
  GoRoute(path: Routes.roleAccess, builder: (context, _) => RoleAccessScreen(onBack: () => context.go(Routes.backOffice))),
  GoRoute(
    path: Routes.barcodeProducts,
    builder: (context, state) {
      // Opened from Stock Manager's Amend Product: go back there.
      final editId = int.tryParse(state.uri.queryParameters['edit'] ?? '');
      return BarcodeProductsScreen(
        key: ValueKey(editId),
        editId: editId,
        onBack: () => context.go(editId == null ? Routes.backOffice : Routes.stockManager),
      );
    },
  ),
  GoRoute(
    path: Routes.stockManager,
    builder: (context, _) => StockManagerScreen(
      onBack: () => context.go(Routes.backOffice),
      onAmendProduct: (id) => context.go('${Routes.barcodeProducts}?edit=$id'),
    ),
  ),
  for (final (path, title, design) in _backOfficeNotPorted)
    GoRoute(path: path, builder: (_, _) => NotPortedScreen(title: title, design: design)),
];
