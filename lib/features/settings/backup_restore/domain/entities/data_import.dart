/// Tables that can be filled from a CSV or Excel file.
///
/// Columns are matched by header name, ignoring case, spaces and
/// underscores; the first name in each list is the database column, the
/// others are friendlier headings. Rows already present (same [keyColumn])
/// are skipped, never overwritten.
enum ImportTable {
  products('Products', 'barcode', {
    'barcode': ['barcode'],
    'description': ['description', 'name', 'item'],
    'price': ['price', 'sellingprice'],
    'departmentId': ['departmentid', 'department', 'dept', 'depid'],
    'stock': ['stock', 'qty', 'quantity'],
    'vat': ['vat'],
    'ageRefusal': ['agerefusal', 'age'],
    'isQuickitem': ['isquickitem', 'quickitem'],
    'caseBarcode': ['casebarcode'],
    'upc': ['upc', 'unitspercase'],
    'cpc': ['cpc', 'costpercase'],
    'costPrice': ['costprice', 'cost'],
    'pluCode': ['plucode', 'plu'],
  }, required: ['barcode', 'description', 'price']),
  departments('Departments', 'name', {
    'id': ['id', 'departmentid'],
    'name': ['name', 'department', 'description'],
    'vat': ['vat'],
    'ageRefusal': ['agerefusal', 'age'],
  }, required: ['name']),
  nonBarcode('Non-barcode items', 'item_id', {
    'item_id': ['itemid', 'id', 'code'],
    'description': ['description', 'name', 'item'],
    'price': ['price'],
    'depid': ['depid', 'departmentid', 'department', 'dept'],
    'vat': ['vat'],
    'ageRefusal': ['agerefusal', 'age'],
  }, required: ['item_id', 'description']);

  const ImportTable(this.label, this.keyColumn, this.columns, {required this.required});
  final String label;
  final String keyColumn;

  /// Database column → accepted headings (lower case, no spaces).
  final Map<String, List<String>> columns;
  final List<String> required;
}

/// What an import did.
typedef ImportSummary = ({int added, int existing, int invalid, List<String> problems});
