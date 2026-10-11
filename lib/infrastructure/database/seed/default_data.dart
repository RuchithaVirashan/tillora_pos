import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/security/password_hasher.dart';
import '../../../core/session/access_rights.dart';
import '../../../core/session/user_session.dart';

/// First-run data.
/// Runs inside the `onCreate` transaction, as one batch.
abstract final class DefaultData {
  /// Special non-barcode item ids the discount flow writes as cart lines.
  static const itemDiscountId = 888888;
  static const saleDiscountId = 999999;

  static Future<void> seed(Transaction txn) async {
    final batch = txn.batch();

    batch.insert('companyDetails', {
      'Name': 'MY COMPANY',
      'Address1': 'ADDRESS1',
      'Address2': 'ADDRESS2',
      'Phone': '00000000',
      'Vatno': '000000000',
      'Phone2': '0000000',
    });

    for (final (name, value) in _sysConfig) {
      batch.insert('sysConfig', {'Parameter': name, 'Value': value});
    }

    for (final (id, name, vat, age) in _departments) {
      batch.insert('departments', {'id': id, 'name': name, 'vat': vat, 'isQuickdept': 1, 'ageRefusal': age});
      batch.insert('subDepartments', {'id': id, 'name': name, 'deptId': id, 'isQuickdept': 0, 'ageRefusal': age});
    }

    for (final (type, text) in _posMessages) {
      batch.insert('posMessages', {'parameter': type, 'value': text});
    }

    for (final name in ['Wages', 'Lottery', 'Fuel', 'Bonus', 'Fruit']) {
      batch.insert('payoutItems', {'PayoutName': name});
    }

    for (final name in ['Gift Voucher', 'Customer Account', 'Cheque', 'Mobile Wallet', 'Bank Transfer', 'Credit Note']) {
      batch.insert('paymentType', {'payment_name': name, 'image_path': '', 'enabled': 1});
    }

    batch.insert('nonBarcodeItems', _nonBarcode(itemDiscountId, 'Item Discount'));
    batch.insert('nonBarcodeItems', _nonBarcode(saleDiscountId, 'Sale Discount'));

    // Role templates (userId 0) and the three starter users.
    final roles = <int, AccessRights>{
      Roles.admin: AccessRights.forRole(maxCount: 1000),
      Roles.manager: AccessRights.forRole(maxCount: 500, denied: _managerDenied),
      Roles.cashier: AccessRights.forRole(maxCount: 100, denied: _cashierDenied),
    };
    for (final MapEntry(key: roleId, value: access) in roles.entries) {
      batch.insert('userAccess', {
        'userId': 0,
        'userName': Roles.name(roleId),
        'roleId': roleId,
        'access': access.toJson(),
      });
    }
    for (final (id, roleId) in [(1, Roles.admin), (2, Roles.manager), (3, Roles.cashier)]) {
      final userName = '${1000 + id}';
      batch.insert('userDetails', {
        'id': id,
        'userName': userName,
        'password': PasswordHasher.hash(userName, userName: userName),
        'roleId': roleId,
      });
    }

    if (kDebugMode) _demoProducts(batch);

    await batch.commit(noResult: true);
  }

  static Map<String, Object?> _nonBarcode(int itemId, String name) =>
      {'item_id': itemId, 'description': name, 'vat': 0.0, 'depid': 99, 'price': 0, 'image_path': '', 'ageRefusal': 0};

  /// A few products so a debug build can ring up a sale before the product
  /// screens are ported. Never added to release builds.
  static void _demoProducts(Batch batch) {
    const items = [
      ('Fresh Milk 1L', '4791111000017', 480.0, 2, 1),
      ('Sliced Bread 450g', '4791111000024', 180.0, 3, 1),
      ('Eggs x10', '4791111000031', 550.0, 2, 1),
      ('Ambul Bananas 1kg', '4791111000048', 320.0, 4, 1),
      ('Plain Tea', '4791111000055', 100.0, 5, 1),
      ('Coffee', '4791111000062', 250.0, 5, 1),
      ('Water 500ml', '4791111000079', 100.0, 5, 1),
      ('Biscuits', '4791111000086', 220.0, 1, 1),
      ('Carrier Bag', '4791111000093', 10.0, 1, 1),
      ('Arrack 750ml', '4791111000109', 3800.0, 8, 0),
    ];
    for (final (name, barcode, price, dept, quick) in items) {
      batch.insert('products', {
        'description': name,
        'barcode': barcode,
        'price': price,
        'departmentId': dept,
        'stock': 50,
        'vat': 0.0,
        'isQuickitem': quick,
        'ageRefusal': dept == 8 ? 21 : 0,
      });
    }
  }

  static const _departments = [
    (1, 'Grocery', 0.0, 0),
    (2, 'Dairy', 0.0, 0),
    (3, 'Bakery', 0.0, 0),
    (4, 'Produce', 0.0, 0),
    (5, 'Drinks', 0.0, 0),
    (6, 'Lottery', 0.0, 0),
    (7, 'Tobacco', 0.0, 21),
    (8, 'Alcohol', 0.0, 21),
    (9, 'Newspapers', 0.0, 0),
    (10, 'Default', 0.0, 0),
  ];

  static const _sysConfig = [
    ('Currency', 'LKR'),
    ('AutoPrint', 'OFF'),
    ('CardPay', 'Enabled'),
    ('maximumQuantity', '99'),
    ('receiptHeader', 'MY COMPANY\nADDRESS1\nADDRESS2'),
    ('receiptFooter', 'THANK YOU FOR YOUR VISIT!'),
    ('ageRefusal', 'Enabled'),
    ('terminalName', 'POS-01'),
    ('lotteryDepartment', '6'),
    ('newsDepartment', '9'),
  ];

  static const _posMessages = [
    ('voidsale', 'Customer cancelled'),
    ('voidsale', 'Insufficient cash'),
    ('voiditem', 'Scanned in error'),
    ('voiditem', 'Customer changed mind'),
    ('voiditem', 'Wrong price'),
    ('voiditem', 'Damaged item'),
    ('nosale', 'Give change for a note'),
    ('nosale', 'Check drawer float'),
    ('nosale', 'Correct a mistake'),
    ('agerefusal', 'Age not reached'),
    ('agerefusal', 'No identification'),
  ];

  static const _managerDenied = {
    'userManagerAccess', 'paymentTypeManagerAccess', 'roleAccessManagerAccess',
    'onlineLotteryAccess', 'newsPaperMagazineAccess',
  };

  static const _cashierDenied = {
    AccessRights.backOffice, AccessRights.cashLift, AccessRights.saleDiscount, AccessRights.priceUpdate,
    'departmentManagerAccess', 'userManagerAccess', 'paymentTypeManagerAccess', 'roleAccessManagerAccess',
    'salesManagerAccess', 'stockManagerAccess', AccessRights.productManager, 'onlineLotteryAccess',
    'newsPaperMagazineAccess', 'labelPrinterAccess', 'promotionManagerAccess',
    'manageNonBarcodeProductsAccess', 'addWeightProductsAccess', 'managePayoutProductAccess',
    'adjustStockAccess', 'allShiftReportAccess', 'exceptionsAccess', 'quickLabelAccess',
    'restorePromotionAccess', 'expiredItemsAccess', 'stockMovementReportAccess', 'saleReportAccess',
    'stockAdjustmentReportAccess',
  };
}
