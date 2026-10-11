import '../../../../../core/errors/result.dart';

typedef ExpiredProduct = ({String barcode, String description, String departmentName, DateTime expiryDate, int stock});

abstract interface class ExpiredItemsRepository {
  /// Products whose expiry date is on or before [onOrBefore], soonest first.
  Future<Result<List<ExpiredProduct>>> expired(DateTime onOrBefore);
}
