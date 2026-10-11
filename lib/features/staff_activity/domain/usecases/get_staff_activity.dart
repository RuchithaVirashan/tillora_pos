import '../../../../core/errors/result.dart';
import '../repositories/staff_activity_repository.dart';

class GetStaffActivity {
  const GetStaffActivity(this._repository);
  final StaffActivityRepository _repository;

  Future<Result<List<StaffStatus>>> call() => _repository.staff();
}
