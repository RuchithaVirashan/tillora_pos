import 'dart:convert';

import 'package:equatable/equatable.dart';

/// What a role is allowed to do. Stored in `userAccess.access` as JSON
/// (`[{"salesAccess":"1", "voidSaleAccessCount":"100", ...}]`) so
/// existing databases keep working.
class AccessRights extends Equatable {
  const AccessRights(this._flags);

  final Map<String, String> _flags;

  // Flag keys as stored in the database.
  static const sales = 'salesAccess';
  static const backOffice = 'backofficeAccess';
  static const noSale = 'noSalesAccess';
  static const noSaleCount = 'noSalesAccessCount';
  static const quickReport = 'quickReportAccess';
  static const voidSale = 'voidSaleAccess';
  static const voidSaleCount = 'voidSaleAccessCount';
  static const voidLine = 'voidLineAccess';
  static const voidLineCount = 'voidLineAccessCount';
  static const refund = 'refundAccess';
  static const cashLift = 'cashLiftAccess';
  static const productDiscount = 'productDiscountAccess';
  static const saleDiscount = 'saleDiscountAccess';
  static const priceUpdate = 'priceUpdateAccess';
  static const productManager = 'productManagerAccess';
  static const priceCheck = 'priceCheckAccess';
  static const shiftEndReport = 'shiftEndReportAccess';

  static const _counts = {noSaleCount, voidSaleCount, voidLineCount};

  /// Every access flag, in storage order.
  static const allFlags = <String>[
    sales, backOffice, noSale, noSaleCount, quickReport, voidSale, voidSaleCount,
    voidLine, voidLineCount, refund, cashLift, productDiscount, saleDiscount, priceUpdate,
    'swapPayTypeAccess', 'departmentManagerAccess', 'userManagerAccess',
    'paymentTypeManagerAccess', 'roleAccessManagerAccess', 'salesManagerAccess',
    'stockManagerAccess', productManager,
    'labelPrinterAccess', 'promotionManagerAccess', 'manageNonBarcodeProductsAccess',
    'addWeightProductsAccess', 'managePayoutProductAccess', 'adjustStockAccess', priceCheck,
    'liveShiftReportAccess', 'allShiftReportAccess', 'exceptionsAccess', 'quickLabelAccess',
    'restorePromotionAccess', shiftEndReport, 'expiredItemsAccess',
    'stockMovementReportAccess', 'saleReportAccess', 'stockAdjustmentReportAccess',
  ];

  /// Admin gets everything; [denied] flags are switched off for other roles.
  factory AccessRights.forRole({required int maxCount, Set<String> denied = const {}}) {
    return AccessRights({
      for (final flag in allFlags)
        flag: _counts.contains(flag) ? '$maxCount' : (denied.contains(flag) ? '0' : '1'),
    });
  }

  factory AccessRights.fromJson(String json) {
    final decoded = jsonDecode(json);
    final map = decoded is List && decoded.isNotEmpty ? decoded.first : decoded;
    return AccessRights({
      for (final e in (map as Map).entries) '${e.key}': '${e.value}',
    });
  }

  static const none = AccessRights({});

  String toJson() => jsonEncode([_flags]);

  bool can(String flag) => _flags[flag] == '1';

  /// Daily limit for counted actions (no sale, void line, void sale).
  int limit(String countFlag) => int.tryParse(_flags[countFlag] ?? '') ?? 0;

  @override
  List<Object?> get props => [_flags];
}
