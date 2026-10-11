import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/validators.dart';
import '../entities/barcode_product.dart';
import '../repositories/barcode_product_repository.dart';

class GetBarcodeProducts {
  const GetBarcodeProducts(this._repository);
  final BarcodeProductRepository _repository;

  Future<Result<List<BarcodeProduct>>> call(String query) => _repository.products(query.trim(), limit: 500);
}

class GetBarcodeProduct {
  const GetBarcodeProduct(this._repository);
  final BarcodeProductRepository _repository;

  Future<Result<BarcodeProduct>> call(int id) async => switch (await _repository.byId(id)) {
    Ok(value: final product?) => Ok(product),
    Ok() => const Err(ValidationFailure('Product not found')),
    Err(:final failure) => Err(failure),
  };
}

/// Checks the fields and that no barcode is used twice, then saves.
class SaveBarcodeProduct {
  const SaveBarcodeProduct(this._repository);
  final BarcodeProductRepository _repository;

  Future<Result<int>> call(BarcodeProduct p) async {
    if (Validators.barcode(p.barcode) case final error?) return Err(ValidationFailure('Barcode: $error'));
    if (p.description.trim().isEmpty) return const Err(ValidationFailure('Enter a description'));
    if (p.priceCents <= 0) return const Err(ValidationFailure('Enter a price above 0'));
    if (p.departmentId == null) return const Err(ValidationFailure('Select a department'));
    if (p.vat < 0 || p.vat > 100) return const Err(ValidationFailure('VAT must be between 0 and 100'));
    if (p.ageLimit < 0 || p.ageLimit > 99) return const Err(ValidationFailure('Enter a valid age limit'));
    if (p.id == null && p.stock < 0) return const Err(ValidationFailure('Initial stock cannot be negative'));

    final codes = {'Barcode': p.barcode};
    if (p.secondaryBarcode case final code? when code.isNotEmpty) {
      if (Validators.barcode(code) case final error?) return Err(ValidationFailure('Secondary barcode: $error'));
      codes['Secondary barcode'] = code;
    }
    if (p.caseBarcode case final code? when code.isNotEmpty) {
      if (Validators.barcode(code) case final error?) return Err(ValidationFailure('Case barcode: $error'));
      if (p.unitsPerCase <= 0) return const Err(ValidationFailure('Enter the units per case'));
      codes['Case barcode'] = code;
    }
    if (p.costPerCaseCents < 0) return const Err(ValidationFailure('Cost per case cannot be negative'));
    if (codes.values.toSet().length != codes.length) return const Err(ValidationFailure('Each barcode must be different'));

    for (final MapEntry(key: label, value: code) in codes.entries) {
      switch (await _repository.barcodeOwner(code, exceptId: p.id)) {
        case Ok(value: final owner?):
          return Err(ValidationFailure('$label $code is already used by $owner'));
        case Err(:final failure):
          return Err(failure);
        case Ok():
      }
    }
    return _repository.save(p);
  }
}

class DeleteBarcodeProduct {
  const DeleteBarcodeProduct(this._repository);
  final BarcodeProductRepository _repository;

  Future<Result<void>> call(BarcodeProduct product) async {
    if (product.inPromotion) return const Err(ValidationFailure('Product is used in Promotion. Please remove it first.'));
    return _repository.delete(product.id!);
  }
}

/// Finds one product to add to the Stock in list.
class FindStockInProduct {
  const FindStockInProduct(this._repository);
  final BarcodeProductRepository _repository;

  Future<Result<BarcodeProduct>> call(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const Err(ValidationFailure('Scan or type a barcode'));
    return switch (await _repository.products(q, limit: 1)) {
      Ok(:final value) when value.isNotEmpty => Ok(value.first),
      Ok() => Err(ValidationFailure('No product found for $q')),
      Err(:final failure) => Err(failure),
    };
  }
}

class ReceiveStock {
  const ReceiveStock(this._repository);
  final BarcodeProductRepository _repository;

  Future<Result<void>> call(List<StockInLine> lines) async {
    final received = lines.where((l) => l.quantity > 0).toList();
    if (received.isEmpty) return const Err(ValidationFailure('Nothing to stock in'));
    return _repository.stockIn(received);
  }
}
