/// Checks and repairs for the local database. [fixes] false only reports.
enum MaintenanceTool {
  databaseCheck('Database Check', 'Run a full health check', fixes: false),
  tables('Check Tables Availability', 'Confirm every table exists and add any missing'),
  transactionTotals('Fix Transaction Mismatches', 'Match sale totals to their items'),
  balances('Fix Balance Mismatches', 'Correct change given on sales'),
  partPay('Fix PartPay Method', 'Correct split payment types'),
  orphanItems('Fix Transaction Items', 'Remove item lines of sales that no longer exist'),
  emptyTransactions('Fix Transaction Records', 'Remove sales with no items'),
  noDepartment('Fix Department 0 Items', 'Move products without a department to Default');

  const MaintenanceTool(this.label, this.description, {this.fixes = true});
  final String label;
  final String description;
  final bool fixes;
}

/// What a check found: [count] problems, with a line about them.
typedef MaintenanceFinding = ({int count, String detail});
