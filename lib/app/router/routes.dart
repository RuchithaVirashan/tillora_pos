/// Route paths, one per screen in the Tillora design canvas.
abstract final class Routes {
  static const home = '/';
  static const login = '/login/:module';
  static String loginFor(String moduleSlug) => '/login/$moduleSlug';

  // Sales. Dialog routes open over the till and return a result with pop().
  static const sales = '/sales';
  static const otherPayment = '/sales/other-payment';
  static const transactions = '/sales/transactions';
  static const holdRecall = '/sales/hold-recall';
  static const voidReason = '/sales/void';
  static const noSale = '/sales/no-sale';
  static const priceCheck = '/sales/price-check';
  static const drawerFloat = '/sales/drawer-float';
  static const discount = '/sales/discount';
  static const payout = '/sales/payout';
  static const weight = '/sales/weight';
  static const quickItems = '/sales/quick-items';
  static const moreFunctions = '/sales/more-functions';
  static const cashLift = '/sales/more-functions/cash-lift';
  static const shiftEnd = '/sales/shift-end';

  // Product management
  static const productManagement = '/products';
  static const suppliers = '/suppliers';
  static const staffActivity = '/staff-activity';

  // Reports
  static const quickReport = '/reports';
  static const shiftReport = '/reports/shift';
  static const exceptions = '/reports/exceptions';
  static const expiredItems = '/reports/expired-items';

  // Back office
  static const backOffice = '/back-office';
  static const departments = '/back-office/departments';
  static const users = '/back-office/users';
  static const paymentTypes = '/back-office/payment-types';
  static const roleAccess = '/back-office/role-access';
  static const salesManager = '/back-office/sales-manager';
  static const stockManager = '/back-office/stock';
  static const barcodeProducts = '/back-office/barcode-products';
  static const labelPrinter = '/back-office/label-printer';
  static const promotions = '/back-office/promotions';
  static const boReports = '/back-office/reports';

  // Settings
  static const settings = '/settings';
  static const organization = '/settings/organization';
  static const systemConfig = '/settings/system';
  static const receipt = '/settings/receipt';
  static const secondScreen = '/settings/second-screen';
  static const inventory = '/settings/inventory';
  static const posMessages = '/settings/pos-messages';
  static const backupRestore = '/settings/backup-restore';
  static const extractProducts = '/settings/extract-products';
}
