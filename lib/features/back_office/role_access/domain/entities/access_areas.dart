import '../../../../../core/session/access_rights.dart';

/// The permission tabs on Role Access Control: label shown → stored flag.
const accessAreas = <(String, List<(String, String)>)>[
  (
    'Sales',
    [
      ('Sales Login Access', AccessRights.sales),
      ('No Sales Access', AccessRights.noSale),
      ('Void Sales Access', AccessRights.voidSale),
      ('Void Line Access', AccessRights.voidLine),
      ('Refund Access', AccessRights.refund),
      ('Cash Lift Access', AccessRights.cashLift),
      ('Product Discount Access', AccessRights.productDiscount),
      ('Sale Discount Access', AccessRights.saleDiscount),
      ('Shift End Report Access', AccessRights.shiftEndReport),
      ('Price Update Access - Price Check', AccessRights.priceUpdate),
      ('Swap Pay Type Access - Transaction History', 'swapPayTypeAccess'),
    ],
  ),
  (
    'Back Office',
    [
      ('Backoffice Login Access', AccessRights.backOffice),
      ('Department Manager Access', 'departmentManagerAccess'),
      ('User Manager Access', 'userManagerAccess'),
      ('Payment Type Manager Access', 'paymentTypeManagerAccess'),
      ('Role Access Manager Access', 'roleAccessManagerAccess'),
      ('Sales Manager Access', 'salesManagerAccess'),
      ('Stock Manager Access', 'stockManagerAccess'),
      ('Label Printer Access', 'labelPrinterAccess'),
      ('Stock Movement Report Access', 'stockMovementReportAccess'),
      ('Sale Report Access', 'saleReportAccess'),
      ('Stock Adjustment Report Access', 'stockAdjustmentReportAccess'),
      ('Promotion Manager Access', 'promotionManagerAccess'),
      ('Restore Promotion Access', 'restorePromotionAccess'),
    ],
  ),
  (
    'Product Manager',
    [
      ('Product Manager Login Access', AccessRights.productManager),
      ('Manage Non-Barcode Products Access', 'manageNonBarcodeProductsAccess'),
      ('Add Weight Products Access', 'addWeightProductsAccess'),
      ('Manage Payout Product Access', 'managePayoutProductAccess'),
      ('Adjust Stock Access', 'adjustStockAccess'),
      ('Price Check Access', AccessRights.priceCheck),
      ('Quick Label Access', 'quickLabelAccess'),
    ],
  ),
  (
    'Reports',
    [
      ('Report Login Access', AccessRights.quickReport),
      ('Live Shift Report Access', 'liveShiftReportAccess'),
      ('All Shift Report Access', 'allShiftReportAccess'),
      ('Exceptions Access', 'exceptionsAccess'),
      ('Expired Items Report Access', 'expiredItemsAccess'),
    ],
  ),
];

/// The daily limits under "Set Count".
const accessCounts = <(String, String)>[
  ('No Sale Access Count', AccessRights.noSaleCount),
  ('Void Sale Access Count', AccessRights.voidSaleCount),
  ('Void Line Access Count', AccessRights.voidLineCount),
];
