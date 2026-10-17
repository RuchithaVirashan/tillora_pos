import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/maintenance_tool.dart';
import '../repositories/maintenance_repository.dart';

class InspectDatabase {
  const InspectDatabase(this._repository);
  final MaintenanceRepository _repository;

  Future<Result<MaintenanceFinding>> call(MaintenanceTool tool) => _repository.inspect(tool);
}

class RepairDatabase {
  const RepairDatabase(this._repository);
  final MaintenanceRepository _repository;

  Future<Result<int>> call(MaintenanceTool tool, MaintenanceFinding finding) async {
    if (!tool.fixes) return Err(ValidationFailure('${tool.label} only reports'));
    if (finding.count == 0) return const Err(ValidationFailure('Nothing to fix'));
    return _repository.fix(tool);
  }
}
