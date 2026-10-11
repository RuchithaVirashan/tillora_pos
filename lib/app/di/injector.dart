import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database;

import '../../core/config/terminal_info.dart';
import '../../core/platform/alert_sounds.dart';
import '../../core/platform/customer_display.dart';
import '../../core/platform/platform_info.dart';
import '../../core/platform/report_output.dart';
import '../../core/platform/system_tools.dart';
import '../../core/session/user_session.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/recent_logins_store.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/product_management/adjust_stock/data/repositories/adjust_stock_repository_impl.dart';
import '../../features/product_management/adjust_stock/domain/repositories/adjust_stock_repository.dart';
import '../../features/product_management/adjust_stock/domain/usecases/adjust_stock_usecases.dart';
import '../../features/product_management/non_barcode/data/repositories/non_barcode_repository_impl.dart';
import '../../features/product_management/non_barcode/domain/repositories/non_barcode_repository.dart';
import '../../features/product_management/non_barcode/domain/usecases/non_barcode_usecases.dart';
import '../../features/product_management/payout_items/data/repositories/payout_items_repository_impl.dart';
import '../../features/product_management/payout_items/domain/repositories/payout_items_repository.dart';
import '../../features/product_management/payout_items/domain/usecases/payout_items_usecases.dart';
import '../../features/product_management/price_change/data/repositories/price_change_repository_impl.dart';
import '../../features/product_management/price_change/domain/repositories/price_change_repository.dart';
import '../../features/product_management/price_change/domain/usecases/price_change_usecases.dart';
import '../../features/product_management/weight_items/data/repositories/weight_items_repository_impl.dart';
import '../../features/product_management/weight_items/domain/repositories/weight_items_repository.dart';
import '../../features/product_management/weight_items/domain/usecases/weight_items_usecases.dart';
import '../../features/reports/exceptions/data/repositories/exceptions_repository_impl.dart';
import '../../features/reports/exceptions/domain/repositories/exceptions_repository.dart';
import '../../features/reports/exceptions/domain/usecases/get_exceptions.dart';
import '../../features/reports/expired_items/data/repositories/expired_items_repository_impl.dart';
import '../../features/reports/expired_items/domain/repositories/expired_items_repository.dart';
import '../../features/reports/expired_items/domain/usecases/get_expired_items.dart';
import '../../features/reports/shift_report/data/repositories/shift_report_repository_impl.dart';
import '../../features/reports/shift_report/domain/repositories/shift_report_repository.dart';
import '../../features/reports/shift_report/domain/usecases/shift_report_usecases.dart';
import '../../features/sales/cart/data/datasources/sales_local_data_source.dart';
import '../../features/sales/cart/data/repositories/sales_repository_impl.dart';
import '../../features/sales/cart/domain/repositories/sales_repository.dart';
import '../../features/sales/cart/domain/usecases/complete_sale.dart';
import '../../features/sales/cart/domain/usecases/get_quick_items.dart';
import '../../features/sales/cart/domain/usecases/print_receipt.dart';
import '../../features/sales/cart/domain/usecases/record_age_refusal.dart';
import '../../features/sales/cart/domain/usecases/scan_item.dart';
import '../../features/sales/cart/domain/usecases/weigh_item.dart';
import '../../features/sales/cash_lift/data/repositories/cash_lift_repository_impl.dart';
import '../../features/sales/cash_lift/domain/repositories/cash_lift_repository.dart';
import '../../features/sales/cash_lift/domain/usecases/lift_cash.dart';
import '../../features/sales/hold_recall/data/repositories/hold_repository_impl.dart';
import '../../features/sales/hold_recall/domain/repositories/hold_repository.dart';
import '../../features/sales/hold_recall/domain/usecases/hold_usecases.dart';
import '../../features/sales/more_functions/data/repositories/till_settings_repository_impl.dart';
import '../../features/sales/more_functions/domain/repositories/till_settings_repository.dart';
import '../../features/sales/more_functions/domain/usecases/set_auto_print.dart';
import '../../features/sales/no_sale/data/repositories/no_sale_repository_impl.dart';
import '../../features/sales/no_sale/domain/repositories/no_sale_repository.dart';
import '../../features/sales/no_sale/domain/usecases/no_sale_usecases.dart';
import '../../features/sales/payment/data/repositories/payment_type_repository_impl.dart';
import '../../features/sales/payment/domain/repositories/payment_type_repository.dart';
import '../../features/sales/payment/domain/usecases/get_payment_types.dart';
import '../../features/sales/payout/data/repositories/payout_repository_impl.dart';
import '../../features/sales/payout/domain/repositories/payout_repository.dart';
import '../../features/sales/payout/domain/usecases/get_payout_reasons.dart';
import '../../features/sales/price_check/data/repositories/price_check_repository_impl.dart';
import '../../features/sales/price_check/domain/repositories/price_check_repository.dart';
import '../../features/sales/price_check/domain/usecases/price_check_usecases.dart';
import '../../features/sales/shift_end/data/repositories/shift_repository_impl.dart';
import '../../features/sales/shift_end/domain/repositories/shift_repository.dart';
import '../../features/sales/shift_end/domain/usecases/end_shift.dart';
import '../../features/sales/transactions/data/repositories/transactions_repository_impl.dart';
import '../../features/sales/transactions/domain/repositories/transactions_repository.dart';
import '../../features/sales/transactions/domain/usecases/transactions_usecases.dart';
import '../../features/sales/void/data/repositories/void_repository_impl.dart';
import '../../features/sales/void/domain/repositories/void_repository.dart';
import '../../features/sales/void/domain/usecases/void_usecases.dart';
import '../../features/staff_activity/data/repositories/staff_activity_repository_impl.dart';
import '../../features/staff_activity/domain/repositories/staff_activity_repository.dart';
import '../../features/staff_activity/domain/usecases/get_staff_activity.dart';
import '../../features/suppliers/data/repositories/supplier_repository_impl.dart';
import '../../features/suppliers/domain/repositories/supplier_repository.dart';
import '../../features/suppliers/domain/usecases/supplier_usecases.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/dao/pos_records_dao.dart';
import '../../infrastructure/database/dao/products_dao.dart';
import '../../infrastructure/database/dao/receipt_dao.dart';
import '../../infrastructure/database/dao/shift_dao.dart';
import '../../infrastructure/database/dao/shift_report_dao.dart';
import '../../infrastructure/database/dao/sys_config_dao.dart';
import '../../infrastructure/hardware/audio_alert_sounds.dart';
import '../../infrastructure/hardware/hardware_registry.dart';
import '../../infrastructure/hardware/multi_window_customer_display.dart';
import '../../infrastructure/hardware/os_system_tools.dart';
import '../../infrastructure/reports/file_report_output.dart';

final getIt = GetIt.instance;

/// Registers shared services, then each feature's repositories and use cases.
/// Add a block here for each new feature.
Future<void> configureDependencies({required AppDatabase database}) async {
  final db = database.db;

  // Shared
  getIt
    ..registerSingleton<AppDatabase>(database)
    // The till printer (sysConfig posprinter), shared by receipts and reports.
    ..registerLazySingleton(() => SystemPrinter(() => getIt<SysConfigDao>().get('posprinter')))
    ..registerLazySingleton(() => HardwareRegistry(receiptPrinter: SystemReceiptPrinter(getIt())))
    ..registerLazySingleton<ReportOutput>(() => FileReportOutput(getIt()))
    ..registerLazySingleton<AlertSounds>(AudioAlertSounds.new)
    ..registerLazySingleton<SystemTools>(OsSystemTools.new)
    ..registerLazySingleton<CustomerDisplay>(() => PlatformInfo.isDesktop ? MultiWindowCustomerDisplay() : NoCustomerDisplay())
    ..registerSingleton<SessionHolder>(SessionHolder())
    ..registerSingleton<SharedPreferences>(await SharedPreferences.getInstance())
    ..registerLazySingleton(() => ProductsDao(db))
    ..registerLazySingleton(() => ShiftDao(db))
    ..registerLazySingleton(() => PosRecordsDao(db))
    ..registerLazySingleton(() => SysConfigDao(db))
    ..registerLazySingleton(() => ShiftReportDao(db, getIt()))
    ..registerLazySingleton(() => ReceiptDao(db, getIt()));

  getIt.registerSingleton(TerminalInfoHolder(await _loadTerminalInfo(getIt<SysConfigDao>())));

  // Auth
  getIt
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(AuthLocalDataSource(db, getIt()), RecentLoginsStore(getIt())))
    ..registerFactory(() => LoginUser(getIt()))
    ..registerFactory(() => GetRecentUserNames(getIt()))
    ..registerFactory(() => ForgetUserName(getIt()));

  // Sales · cart
  getIt
    ..registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl(SalesLocalDataSource(db, getIt()), getIt(), getIt(), getIt()))
    ..registerFactory(() => ScanItem(getIt()))
    ..registerFactory(() => CompleteSale(getIt()))
    ..registerFactory(() => GetQuickItems(getIt()))
    ..registerFactory(() => RecordAgeRefusal(getIt()))
    ..registerFactory(() => GetWeighedProducts(getIt()))
    ..registerFactory(() => PrintReceipt(getIt()));

  // Sales · dialogs
  getIt
    ..registerLazySingleton<VoidRepository>(() => VoidRepositoryImpl(getIt()))
    ..registerFactory(() => GetVoidOptions(getIt()))
    ..registerFactory(() => RecordVoid(getIt()))
    ..registerLazySingleton<NoSaleRepository>(() => NoSaleRepositoryImpl(getIt(), getIt()))
    ..registerFactory(() => GetNoSaleOptions(getIt()))
    ..registerFactory(() => OpenDrawerNoSale(getIt()))
    ..registerLazySingleton<HoldRepository>(() => HoldRepositoryImpl(db))
    ..registerFactory(() => GetHeldSales(getIt()))
    ..registerFactory(() => HoldSale(getIt()))
    ..registerFactory(() => RecallSale(getIt()))
    ..registerLazySingleton<PaymentTypeRepository>(() => PaymentTypeRepositoryImpl(db))
    ..registerFactory(() => GetPaymentTypes(getIt()))
    ..registerLazySingleton<PriceCheckRepository>(() => PriceCheckRepositoryImpl(getIt()))
    ..registerFactory(() => SearchProducts(getIt()))
    ..registerFactory(() => UpdatePrice(getIt()))
    ..registerFactory(() => SetExpiry(getIt()))
    ..registerLazySingleton<ShiftRepository>(() => ShiftRepositoryImpl(getIt(), getIt()))
    ..registerFactory(() => EndShift(getIt()))
    ..registerLazySingleton<PayoutRepository>(() => PayoutRepositoryImpl(db))
    ..registerFactory(() => GetPayoutReasons(getIt()))
    ..registerLazySingleton<CashLiftRepository>(() => CashLiftRepositoryImpl(db, getIt()))
    ..registerFactory(() => LiftCash(getIt()))
    ..registerLazySingleton<TransactionsRepository>(() => TransactionsRepositoryImpl(db))
    ..registerFactory(() => GetShiftTransactions(getIt()))
    ..registerFactory(() => GetTransactionLines(getIt()))
    ..registerFactory(() => GetPayTypeOptions(getIt()))
    ..registerFactory(() => SwapPayType(getIt()))
    ..registerLazySingleton<TillSettingsRepository>(() => TillSettingsRepositoryImpl(getIt(), getIt(), getIt()))
    ..registerFactory(() => SetAutoPrint(getIt()))
    ..registerFactory(() => SetCustomerDisplay(getIt()));

  _registerProductManagement(db);
  _registerReports(db);

  getIt
    ..registerLazySingleton<SupplierRepository>(() => SupplierRepositoryImpl(db))
    ..registerFactory(() => GetSuppliers(getIt()))
    ..registerFactory(() => SaveSupplier(getIt()))
    ..registerFactory(() => DeleteSupplier(getIt()))
    ..registerLazySingleton<StaffActivityRepository>(() => StaffActivityRepositoryImpl(db))
    ..registerFactory(() => GetStaffActivity(getIt()));
}

void _registerProductManagement(Database db) {
  getIt
    ..registerLazySingleton<NonBarcodeRepository>(() => NonBarcodeRepositoryImpl(db, getIt()))
    ..registerFactory(() => GetNonBarcodeItems(getIt()))
    ..registerFactory(() => GetNonBarcodeSetup(getIt()))
    ..registerFactory(() => AddNonBarcodeItem(getIt()))
    ..registerFactory(() => DeleteNonBarcodeItem(getIt()))
    ..registerLazySingleton<WeightItemsRepository>(() => WeightItemsRepositoryImpl(db, getIt()))
    ..registerFactory(() => GetWeightProducts(getIt()))
    ..registerFactory(() => GetWeightDepartments(getIt()))
    ..registerFactory(() => AddWeightProduct(getIt()))
    ..registerLazySingleton<PayoutItemsRepository>(() => PayoutItemsRepositoryImpl(db))
    ..registerFactory(() => GetPayoutItems(getIt()))
    ..registerFactory(() => AddPayoutItem(getIt()))
    ..registerFactory(() => DeletePayoutItem(getIt()))
    ..registerLazySingleton<AdjustStockRepository>(() => AdjustStockRepositoryImpl(db))
    ..registerFactory(() => FindStockItem(getIt()))
    ..registerFactory(() => AdjustStock(getIt()))
    ..registerLazySingleton<PriceChangeRepository>(() => PriceChangeRepositoryImpl(getIt()))
    ..registerFactory(() => FindPricedProduct(getIt()))
    ..registerFactory(() => ChangePrice(getIt()))
    ..registerFactory(() => SetProductExpiry(getIt()));
}

void _registerReports(Database db) {
  getIt
    ..registerLazySingleton<ShiftReportRepository>(() => ShiftReportRepositoryImpl(getIt()))
    ..registerFactory(() => GetLiveShifts(getIt()))
    ..registerFactory(() => FindShifts(getIt()))
    ..registerFactory(() => GetReportUsers(getIt()))
    ..registerFactory(() => GetShiftReport(getIt()))
    ..registerLazySingleton<ExceptionsRepository>(() => ExceptionsRepositoryImpl(db))
    ..registerFactory(() => GetExceptions(getIt()))
    ..registerLazySingleton<ExpiredItemsRepository>(() => ExpiredItemsRepositoryImpl(db))
    ..registerFactory(() => GetExpiredItems(getIt()));
}

Future<TerminalInfo> _loadTerminalInfo(SysConfigDao config) async {
  const fallback = TerminalInfo.fallback;
  final values = await config.getMany(['terminalName', 'AutoPrint', 'ageRefusal', 'maximumQuantity', 'customerDisplay']);
  final company = await config.companyName();
  return TerminalInfo(
    companyName: company.isEmpty ? fallback.companyName : company,
    terminalName: values['terminalName'] ?? fallback.terminalName,
    autoPrint: values['AutoPrint']?.toUpperCase() == 'ON',
    ageCheckEnabled: (values['ageRefusal'] ?? 'Enabled') == 'Enabled',
    maxQuantity: int.tryParse(values['maximumQuantity'] ?? '') ?? fallback.maxQuantity,
    customerDisplay: values['customerDisplay']?.toUpperCase() == 'ON',
  );
}
