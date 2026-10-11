/// CREATE TABLE statements for the local database.
///
/// `cloudSync`/`tSync` columns are kept for compatibility with existing
/// databases, even though Tillora runs local-only for now.
abstract final class Schema {
  static const tables = <String>[
    '''
CREATE TABLE IF NOT EXISTS companyDetails (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL,
  Address1 TEXT NOT NULL,
  Address2 TEXT NOT NULL,
  Phone TEXT NOT NULL,
  Vatno TEXT NOT NULL,
  Phone2 TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS supplierDetails (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  email TEXT NOT NULL,
  phoneNumber TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS userDetails (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userName TEXT NOT NULL,
  password TEXT NOT NULL,
  roleId INTEGER NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS sysConfig (
  idSysConfig INTEGER PRIMARY KEY AUTOINCREMENT,
  Parameter TEXT NOT NULL,
  Value TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS Settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  setting_name TEXT NOT NULL,
  setting TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS nonBarcodeItems (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  vat REAL NOT NULL,
  depid INTEGER NOT NULL,
  price REAL NOT NULL,
  image_path TEXT NOT NULL,
  ageRefusal INTEGER,
  cloudSync INTEGER DEFAULT 0,
  parentId INTEGER DEFAULT NULL,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS saleOnHold (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  hold_datetime TEXT NOT NULL,
  items TEXT NOT NULL,
  total REAL NOT NULL,
  item_count INTEGER NOT NULL,
  logid INTEGER,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS logDetails (
  LogId INTEGER PRIMARY KEY AUTOINCREMENT,
  Userid TEXT NOT NULL,
  ShiftStarted TEXT NOT NULL,
  ShiftEnd TEXT NOT NULL,
  Status TEXT NOT NULL,
  drawfloat REAL NOT NULL,
  dup_prints INTEGER NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  Tid INTEGER DEFAULT 1,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  barcode TEXT NOT NULL,
  price REAL NOT NULL,
  departmentId INTEGER NOT NULL,
  stock INTEGER NOT NULL,
  vat REAL NOT NULL,
  caseBarcode TEXT,
  upc TEXT,
  tax TEXT,
  pluCode TEXT,
  imagePath TEXT,
  isQuickitem INTEGER NOT NULL,
  ageRefusal INTEGER,
  cloudSync INTEGER DEFAULT 0,
  subDeptId INTEGER DEFAULT NULL,
  wasPrice REAL,
  priceUpdated INTEGER NOT NULL DEFAULT 0,
  expiryDate TEXT,
  tSync INTEGER DEFAULT 0,
  cpc REAL DEFAULT 0.0,
  costPrice REAL DEFAULT 0.0,
  margin REAL DEFAULT 0.0,
  webPrice REAL,
  web_product INTEGER NOT NULL DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS Transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  total_payable REAL NOT NULL,
  cus_paid_amount REAL NOT NULL,
  cus_balance REAL NOT NULL,
  transaction_date TEXT NOT NULL,
  type TEXT,
  method2 TEXT,
  method1 TEXT,
  user_id TEXT,
  item_count INTEGER NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  Tid INTEGER DEFAULT 1,
  method1Id INTEGER DEFAULT NULL,
  method2Id INTEGER DEFAULT NULL,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS TransactionItems (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER,
  item TEXT,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  amount REAL NOT NULL,
  dep_id INTEGER,
  vat REAL,
  promo TEXT,
  promo_val REAL,
  cloudSync INTEGER DEFAULT 0,
  Tid INTEGER DEFAULT 1,
  tSync INTEGER DEFAULT 0,
  FOREIGN KEY (transaction_id) REFERENCES Transactions(id)
)''',
    '''
CREATE TABLE IF NOT EXISTS departments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  vat REAL NOT NULL,
  isQuickdept INTEGER NOT NULL,
  ageRefusal INTEGER,
  cloudSync INTEGER DEFAULT 0,
  groupId INTEGER DEFAULT 1,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS subDepartments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  deptId INTEGER NOT NULL,
  isQuickdept INTEGER NOT NULL,
  ageRefusal INTEGER,
  cloudSync INTEGER DEFAULT 0,
  groupId INTEGER DEFAULT 1,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS SoldItems (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  TranId INTEGER NOT NULL,
  Price REAL NOT NULL,
  Qty INTEGER NOT NULL,
  Total REAL NOT NULL,
  logid INTEGER NOT NULL,
  Description TEXT NOT NULL,
  Barcode TEXT NOT NULL,
  type TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  Tid INTEGER DEFAULT 1,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS posRecords (
  Rec_Id INTEGER PRIMARY KEY AUTOINCREMENT,
  Rec_Type TEXT NOT NULL,
  Rec_Date TEXT NOT NULL,
  Record TEXT NOT NULL,
  LogId INTEGER NOT NULL,
  Rec_Item TEXT NOT NULL,
  reason TEXT,
  cloudSync INTEGER DEFAULT 0,
  Tid INTEGER DEFAULT 1,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS posMessages (
  mid INTEGER PRIMARY KEY AUTOINCREMENT,
  parameter TEXT NOT NULL,
  value TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS displayConfig (
  idDisplayConfig INTEGER PRIMARY KEY AUTOINCREMENT,
  Parameter TEXT NOT NULL,
  Value TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS payoutItems (
  PayoutID INTEGER PRIMARY KEY AUTOINCREMENT,
  PayoutName TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS userAccess (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  userName TEXT NOT NULL,
  roleId INTEGER NOT NULL,
  access TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS cashLift (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  logId INTEGER NOT NULL,
  liftAt TEXT NOT NULL,
  amount REAL NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0,
  FOREIGN KEY (logId) REFERENCES logDetails(LogId)
)''',
    '''
CREATE TABLE IF NOT EXISTS paymentType (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payment_name TEXT NOT NULL,
  image_path TEXT NOT NULL,
  enabled INTEGER DEFAULT 0,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS promotions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  startDate TEXT NOT NULL,
  endDate TEXT NOT NULL,
  promotionType TEXT NOT NULL,
  qty TEXT DEFAULT 1,
  amount REAL DEFAULT 0.00,
  cloudSync INTEGER DEFAULT 0,
  supId INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS promotionItems (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  promotionId INTEGER NOT NULL,
  productId INTEGER NOT NULL,
  groupId INTEGER DEFAULT 1,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0,
  FOREIGN KEY (promotionId) REFERENCES promotions (id) ON DELETE CASCADE
)''',
    '''
CREATE TABLE IF NOT EXISTS vat (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  categoryid INTEGER NOT NULL,
  vat REAL NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS sysMessage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_code TEXT NOT NULL UNIQUE,
  message_text TEXT NOT NULL,
  message_type TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS lottery (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  barcode TEXT NOT NULL,
  price REAL NOT NULL,
  departmentId INTEGER NOT NULL,
  subDeptId INTEGER DEFAULT NULL,
  vat REAL NOT NULL,
  ageRefusal INTEGER,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS newsAndMagazines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  barcode TEXT NOT NULL,
  price REAL NOT NULL,
  departmentId INTEGER NOT NULL,
  subDeptId INTEGER DEFAULT NULL,
  stock INTEGER NOT NULL,
  vat REAL NOT NULL,
  type TEXT,
  caseBarcode TEXT,
  upc TEXT,
  tax TEXT,
  pluCode TEXT,
  ageRefusal INTEGER,
  cloudSync INTEGER DEFAULT 0,
  prev_barcode TEXT DEFAULT NULL,
  prev_price REAL DEFAULT NULL,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS secondaryBarcode (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  prodId INTEGER NOT NULL,
  barcode TEXT NOT NULL,
  price REAL NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS terminals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  createdAt TEXT NOT NULL,
  lastLoggedAt TEXT DEFAULT NULL,
  live INTEGER DEFAULT 0,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS supplierProductCatelog (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  barcode TEXT NOT NULL,
  price REAL NOT NULL,
  vat REAL NOT NULL,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS temp (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT NOT NULL,
  value TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS stockAdjustment (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  barcode TEXT NOT NULL,
  beforeStock INTEGER NOT NULL,
  afterStock INTEGER NOT NULL,
  adjustmentQuantity INTEGER NOT NULL,
  adjustmentType TEXT NOT NULL,
  adjustedAt TEXT NOT NULL,
  cloudSync INTEGER DEFAULT 0,
  Tid INTEGER DEFAULT 1,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS supplierPromotions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  startDate TEXT NOT NULL,
  endDate TEXT NOT NULL,
  promotionType TEXT NOT NULL,
  qty TEXT DEFAULT 1,
  amount REAL DEFAULT 0.00,
  cloudSync INTEGER DEFAULT 0,
  supId INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0
)''',
    '''
CREATE TABLE IF NOT EXISTS supplierPromotionItems (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  promotionId INTEGER NOT NULL,
  productId INTEGER NOT NULL,
  groupId INTEGER DEFAULT 1,
  cloudSync INTEGER DEFAULT 0,
  tSync INTEGER DEFAULT 0,
  FOREIGN KEY (promotionId) REFERENCES supplierPromotions (id) ON DELETE CASCADE
)''',
  ];

  /// Indexes for barcode lookups and per-shift reports.
  static const indexes = <String>[
    'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode COLLATE NOCASE)',
    'CREATE INDEX IF NOT EXISTS idx_products_quick ON products(isQuickitem)',
    'CREATE INDEX IF NOT EXISTS idx_secondary_barcode ON secondaryBarcode(barcode COLLATE NOCASE)',
    'CREATE INDEX IF NOT EXISTS idx_lottery_barcode ON lottery(barcode COLLATE NOCASE)',
    'CREATE INDEX IF NOT EXISTS idx_news_barcode ON newsAndMagazines(barcode COLLATE NOCASE)',
    'CREATE INDEX IF NOT EXISTS idx_txitems_tx ON TransactionItems(transaction_id)',
    'CREATE INDEX IF NOT EXISTS idx_tx_user ON Transactions(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_sold_log ON SoldItems(logid)',
    'CREATE INDEX IF NOT EXISTS idx_records_log ON posRecords(LogId)',
    'CREATE INDEX IF NOT EXISTS idx_log_user_status ON logDetails(Userid, Status)',
    'CREATE INDEX IF NOT EXISTS idx_hold_log ON saleOnHold(logid)',
    'CREATE INDEX IF NOT EXISTS idx_sysconfig_param ON sysConfig(Parameter)',
  ];
}
