import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/sale_line.dart';
import '../repositories/sales_manager_repository.dart';

class GetClosedShifts {
  const GetClosedShifts(this._repository);
  final SalesManagerRepository _repository;

  Future<Result<List<ShiftOption>>> call(DateTime from, DateTime to) => _repository.shifts(from, to);
}

class GetSaleLines {
  const GetSaleLines(this._repository);
  final SalesManagerRepository _repository;

  Future<Result<List<SaleLine>>> call(DateTime from, DateTime to, {int? logId}) async {
    if (!to.isAfter(from)) return const Err(ValidationFailure('End date must be after the start date'));
    return _repository.lines(from, to, logId: logId);
  }
}

/// Misfired lines: rung up by mistake and taken off their sales.
class RemoveSaleLines {
  const RemoveSaleLines(this._repository);
  final SalesManagerRepository _repository;

  Future<Result<void>> call(List<SaleLine> lines) async {
    if (lines.isEmpty) return const Err(ValidationFailure('No item selected. Please select an item first.'));
    return _repository.remove(lines);
  }
}

/// Lowers the quantity of one misfired line; 0 takes it off.
class AlterSaleLine {
  const AlterSaleLine(this._repository);
  final SalesManagerRepository _repository;

  Future<Result<void>> call(SaleLine line, int quantity) async {
    if (quantity < 0) return const Err(ValidationFailure('Enter a quantity'));
    if (quantity >= line.quantity) return Err(ValidationFailure('Enter a quantity below ${line.quantity}'));
    if (quantity == 0) return _repository.remove([line]);
    return _repository.alter(line, quantity);
  }
}
