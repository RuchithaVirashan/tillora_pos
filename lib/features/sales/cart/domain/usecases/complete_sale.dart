import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/training_mode.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/cart.dart';
import '../repositories/sales_repository.dart';

class CompleteSaleParams {
  const CompleteSaleParams(this.cart, {required this.logId});

  final Cart cart;
  final int logId;
}

/// Saves a fully paid cart and opens the drawer when cash moves.
class CompleteSale implements UseCase<int, CompleteSaleParams> {
  const CompleteSale(this._repository, [this._training]);

  final SalesRepository _repository;
  final TrainingMode? _training;

  @override
  Future<Result<int>> call(CompleteSaleParams params) async {
    final cart = params.cart;
    if (!cart.isPaid) return const Err(ValidationFailure('The sale is not fully paid'));
    // Practice sales are not saved and leave stock and the drawer alone.
    if (_training?.value ?? false) return const Ok(TrainingMode.practiceSaleId);

    final saved = await _repository.saveSale(cart, logId: params.logId);
    // Open for cash taken, and for change given back on a card or voucher
    // overpayment.
    if (saved.isSuccess && (cart.changeCents > 0 || cart.tenders.any((t) => t.method == Tender.cashMethod))) {
      // A drawer that fails to open must not undo a saved sale.
      await _repository.openCashDrawer();
    }
    return saved;
  }
}
