import 'package:get_it/get_it.dart';

import '../../core/config/terminal_info.dart';
import '../../core/platform/alert_sounds.dart';
import '../../core/platform/system_tools.dart';
import '../../core/session/user_session.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/sales/cart/data/datasources/sales_local_data_source.dart';
import '../../features/sales/cart/data/repositories/sales_repository_impl.dart';
import '../../features/sales/cart/domain/repositories/sales_repository.dart';
import '../../features/sales/cart/domain/usecases/complete_sale.dart';
import '../../features/sales/cart/domain/usecases/get_quick_items.dart';
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
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/dao/pos_records_dao.dart';
import '../../infrastructure/database/dao/products_dao.dart';
import '../../infrastructure/database/dao/shift_dao.dart';
import '../../infrastructure/database/dao/sys_config_dao.dart';
import '../../infrastructure/hardware/audio_alert_sounds.dart';
import '../../infrastructure/hardware/hardware_registry.dart';
import '../../infrastructure/hardware/os_system_tools.dart';

final getIt = GetIt.instance;

/// Registers shared services, then each feature's repositories and use cases.
/// Add a block here for each new feature.
Future<void> configureDependencies({required AppDatabase database}) async {
  final db = database.db;

  // Shared
  getIt
    ..registerSingleton<AppDatabase>(database)
    ..registerLazySingleton<HardwareRegistry>(HardwareRegistry.forCurrentPlatform)
    ..registerLazySingleton<AlertSounds>(AudioAlertSounds.new)
    ..registerLazySingleton<SystemTools>(OsSystemTools.new)
    ..registerSingleton<SessionHolder>(SessionHolder())
    ..registerLazySingleton(() => ProductsDao(db))
    ..registerLazySingleton(() => ShiftDao(db))
    ..registerLazySingleton(() => PosRecordsDao(db))
    ..registerLazySingleton(() => SysConfigDao(db));

  getIt.registerSingleton(TerminalInfoHolder(await _loadTerminalInfo(getIt<SysConfigDao>())));

  // Auth
  getIt
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(AuthLocalDataSource(db, getIt())))
    ..registerFactory(() => LoginUser(getIt()));

  // Sales · cart
  getIt
    ..registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl(SalesLocalDataSource(db, getIt()), getIt(), getIt()))
    ..registerFactory(() => ScanItem(getIt()))
    ..registerFactory(() => CompleteSale(getIt()))
    ..registerFactory(() => GetQuickItems(getIt()))
    ..registerFactory(() => RecordAgeRefusal(getIt()))
    ..registerFactory(() => GetWeighedProducts(getIt()));

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
    ..registerLazySingleton<ShiftRepository>(() => ShiftRepositoryImpl(db, getIt(), getIt()))
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
    ..registerLazySingleton<TillSettingsRepository>(() => TillSettingsRepositoryImpl(getIt(), getIt()))
    ..registerFactory(() => SetAutoPrint(getIt()));
}

Future<TerminalInfo> _loadTerminalInfo(SysConfigDao config) async {
  const fallback = TerminalInfo.fallback;
  final values = await config.getMany(['terminalName', 'AutoPrint', 'ageRefusal', 'maximumQuantity']);
  final company = await config.companyName();
  return TerminalInfo(
    companyName: company.isEmpty ? fallback.companyName : company,
    terminalName: values['terminalName'] ?? fallback.terminalName,
    autoPrint: values['AutoPrint']?.toUpperCase() == 'ON',
    ageCheckEnabled: (values['ageRefusal'] ?? 'Enabled') == 'Enabled',
    maxQuantity: int.tryParse(values['maximumQuantity'] ?? '') ?? fallback.maxQuantity,
  );
}
