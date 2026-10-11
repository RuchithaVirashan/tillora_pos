import '../../../../../core/errors/result.dart';
import '../entities/barcode_product.dart';

/// A line on the Stock in list: [quantity] units of a product to receive.
typedef StockInLine = ({int productId, String barcode, String description, int quantity});

abstract interface class BarcodeProductRepository {
  /// Weighed products are left out. [query] matches the barcode exactly or
  /// the description; empty lists everything A–Z.
  Future<Result<List<BarcodeProduct>>> products(String query, {int limit});

  Future<Result<BarcodeProduct?>> byId(int id);

  /// Main, secondary or case barcode of the product with the code, other
  /// than [exceptId]. Null when the code is free.
  Future<Result<String?>> barcodeOwner(String code, {int? exceptId});

  /// Inserts ([BarcodeProduct.id] null) or updates. Returns the id.
  Future<Result<int>> save(BarcodeProduct product);

  Future<Result<void>> delete(int id);

  /// Adds each line's quantity to stock and logs it, in one transaction.
  Future<Result<void>> stockIn(List<StockInLine> lines);
}
