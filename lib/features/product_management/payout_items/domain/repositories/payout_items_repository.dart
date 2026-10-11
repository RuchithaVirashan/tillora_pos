import '../../../../../core/errors/result.dart';

typedef PayoutItem = ({int id, String name});

abstract interface class PayoutItemsRepository {
  Future<Result<List<PayoutItem>>> items();
  Future<Result<void>> add(String name);
  Future<Result<void>> delete(int id);
}
