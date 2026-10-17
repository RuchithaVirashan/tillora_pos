import 'dart:typed_data';

import '../../../../../core/errors/result.dart';
import '../entities/promotion.dart';

/// One product line read from a promotions spreadsheet.
typedef PromoSheetRow = ({String description, String barcode});

/// The rows of a promotions spreadsheet and the date range it covers.
typedef PromoSheet = ({DateTime? start, DateTime? end, List<PromoSheetRow> rows});

/// A product already in another promotion over the same dates.
typedef PromoClash = ({String product, String promotion});

abstract interface class PromotionRepository {
  /// Newest first. [query] matches the id, the description or the barcode
  /// of a product in the promotion.
  Future<Result<List<PromotionSummary>>> promotions(String query);

  Future<Result<Promotion?>> byId(int id);

  /// Main or secondary barcode.
  Future<Result<PromoProduct?>> productByBarcode(String barcode);

  /// Products of [productIds] in another promotion whose dates overlap.
  Future<Result<List<PromoClash>>> clashes(Iterable<int> productIds, DateTime start, DateTime end, {int? exceptId});

  /// A promotion with the same description and dates already exists.
  Future<Result<bool>> exists(String description, DateTime start, DateTime end);

  /// Inserts ([Promotion.id] null) or replaces the promotion and its items.
  Future<Result<int>> save(Promotion promotion);

  Future<Result<void>> delete(int id);

  /// Reads the first sheet of an XLSX file.
  Future<Result<PromoSheet>> readSheet(Uint8List bytes);
}
