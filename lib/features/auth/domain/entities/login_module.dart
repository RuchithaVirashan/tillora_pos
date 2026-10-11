import '../../../../core/session/access_rights.dart';

/// The areas of the app that need a login, with the access flag each checks.
/// Matches the `module` options on Login.dc.html.
enum LoginModule {
  sales('sales', 'Sales', 'SALES', 'Staff need sales access to open the till.', AccessRights.sales),
  backOffice('back-office', 'Back Office Panel', 'BACK OFFICE', 'Back office access is set in Role Access Control.', AccessRights.backOffice),
  products('products', 'Product Management', 'PRODUCT MANAGEMENT', 'Manage non-barcode, weight and payout products.', AccessRights.productManager),
  reports('reports', 'Report', 'QUICK REPORT', 'Report login access is set in System Configuration.', AccessRights.quickReport),
  settings('settings', 'Settings', 'SETTINGS', 'Only admin can access settings.', null);

  const LoginModule(this.slug, this.title, this.badge, this.note, this.accessFlag);

  final String slug;
  final String title;
  final String badge;
  final String note;

  /// Null means admin only.
  final String? accessFlag;

  static LoginModule fromSlug(String? slug) =>
      values.firstWhere((m) => m.slug == slug, orElse: () => LoginModule.sales);
}
