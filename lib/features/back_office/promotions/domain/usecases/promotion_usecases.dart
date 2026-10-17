import 'dart:typed_data';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/money.dart';
import '../entities/promotion.dart';
import '../repositories/promotion_repository.dart';

class GetPromotions {
  const GetPromotions(this._repository);
  final PromotionRepository _repository;

  Future<Result<List<PromotionSummary>>> call(String query) => _repository.promotions(query.trim());
}

class GetPromotion {
  const GetPromotion(this._repository);
  final PromotionRepository _repository;

  Future<Result<Promotion>> call(int id) async => switch (await _repository.byId(id)) {
    Ok(value: final p?) => Ok(p),
    Ok() => const Err(ValidationFailure('Promotion not found')),
    Err(:final failure) => Err(failure),
  };
}

class FindPromoProduct {
  const FindPromoProduct(this._repository);
  final PromotionRepository _repository;

  Future<Result<PromoProduct>> call(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return const Err(ValidationFailure('Scan a barcode'));
    return switch (await _repository.productByBarcode(code)) {
      Ok(value: final p?) => Ok(p),
      Ok() => Err(ValidationFailure('No product found for $code')),
      Err(:final failure) => Err(failure),
    };
  }
}

/// Checks the promotion, sets its quantity for bundles and meal deals,
/// and refuses products already on offer over the same dates.
class SavePromotion {
  const SavePromotion(this._repository);
  final PromotionRepository _repository;

  Future<Result<int>> call(Promotion promotion) async {
    var p = promotion;
    if (p.description.trim().isEmpty) return const Err(ValidationFailure('Enter a description'));
    if (p.end.isBefore(p.start)) return const Err(ValidationFailure('End date must be on or after the start date'));
    if (p.amountCents <= 0) return const Err(ValidationFailure('Enter an amount above 0'));

    final ids = [for (final item in p.products) item.productId];
    if (ids.isEmpty) return const Err(ValidationFailure('No products added for this promotion'));
    if (ids.toSet().length != ids.length) {
      return const Err(ValidationFailure('Same product cannot be used in multiple groups'));
    }
    switch (p.type) {
      case PromoType.buyXGetY:
        if (p.qty < 1) return const Err(ValidationFailure('Enter the quantity'));
      case PromoType.bundle:
        if (ids.length < 2) return const Err(ValidationFailure('Add at least 2 products to the bundle'));
        p = p.copyWith(qty: ids.length);
      case PromoType.mealDeal:
        for (var g = 1; g <= PromoType.mealDeal.groupNames.length; g++) {
          if (p.groups[g]?.isEmpty ?? true) return const Err(ValidationFailure('Please add products to groups 1, 2, and 3 for Meal Deal'));
        }
        p = p.copyWith(qty: PromoType.mealDeal.groupNames.length);
    }

    switch (await _repository.clashes(ids, p.start, p.end, exceptId: p.id)) {
      case Ok(value: [final clash, ...]):
        return Err(ValidationFailure('${clash.product} is already in promotion ${clash.promotion}'));
      case Err(:final failure):
        return Err(failure);
      case Ok():
    }
    return _repository.save(p);
  }
}

class DeletePromotion {
  const DeletePromotion(this._repository);
  final PromotionRepository _repository;

  Future<Result<void>> call(int id) => _repository.delete(id);
}

typedef RestoreSummary = ({int added, int skipped, int unknownProducts});

/// Adds promotions from a supplier spreadsheet: one product per row, the
/// offer in column F (e.g. "3 FOR Rs 600"), the barcode in column I and the
/// date range in D4 ("01/10/2026 - 31/10/2026"). Consecutive rows with the
/// same offer text make one promotion. Promotions already added, or whose
/// products are on another offer, are skipped.
class RestorePromotions {
  const RestorePromotions(this._repository, this._save);
  final PromotionRepository _repository;
  final SavePromotion _save;

  static final _multi = RegExp(r'(\d+)\s*FOR\s*(?:Rs\.?|LKR|£)?\s*([\d,]+(?:\.\d+)?)', caseSensitive: false);
  static final _single = RegExp(r'(?:Rs\.?|LKR|£)\s*([\d,]+(?:\.\d+)?)', caseSensitive: false);

  /// `(qty, amount)` from offer text, or null when it has no price.
  static (int, int)? parseOffer(String text) {
    int cents(String v) => Money.toCents(double.tryParse(v.replaceAll(',', '')) ?? 0);
    if (_multi.firstMatch(text) case final m?) return (int.parse(m[1]!), cents(m[2]!));
    if (_single.firstMatch(text) case final m?) return (1, cents(m[1]!));
    return null;
  }

  Future<Result<RestoreSummary>> call(Uint8List bytes) async {
    final PromoSheet sheet;
    switch (await _repository.readSheet(bytes)) {
      case Ok(:final value):
        sheet = value;
      case Err(:final failure):
        return Err(failure);
    }
    final (start, end) = (sheet.start, sheet.end);
    if (start == null || end == null) return const Err(ValidationFailure('Date range not found in cell D4 (dd/MM/yyyy - dd/MM/yyyy)'));

    // Consecutive rows with the same offer text.
    final offers = <(String, List<String>)>[];
    for (final row in sheet.rows) {
      if (parseOffer(row.description) == null) continue;
      if (offers.isNotEmpty && offers.last.$1 == row.description) {
        offers.last.$2.add(row.barcode);
      } else {
        offers.add((row.description, [row.barcode]));
      }
    }
    if (offers.isEmpty) return const Err(ValidationFailure('No promotions found in the file'));

    var added = 0, skipped = 0, unknown = 0;
    for (final (text, barcodes) in offers) {
      final (qty, amount) = parseOffer(text)!;
      if (await _repository.exists(text, start, end) case Ok(value: true)) {
        skipped++;
        continue;
      }
      final products = <PromoProduct>[];
      for (final code in barcodes) {
        switch (await _repository.productByBarcode(code)) {
          case Ok(value: final p?) when !products.contains(p):
            products.add(p);
          case Ok(value: null):
            unknown++;
          default:
        }
      }
      if (products.isEmpty) {
        skipped++;
        continue;
      }
      final result = await _save(Promotion(
        description: text,
        type: PromoType.buyXGetY,
        start: start,
        end: end,
        qty: qty,
        amountCents: amount,
        groups: {1: products},
      ));
      if (result is Ok) {
        added++;
      } else {
        skipped++;
      }
    }
    return Ok((added: added, skipped: skipped, unknownProducts: unknown));
  }
}
