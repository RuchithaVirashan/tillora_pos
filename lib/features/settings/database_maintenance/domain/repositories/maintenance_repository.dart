import '../../../../../core/errors/result.dart';
import '../entities/maintenance_tool.dart';

abstract interface class MaintenanceRepository {
  /// Looks for problems without changing anything.
  Future<Result<MaintenanceFinding>> inspect(MaintenanceTool tool);

  /// Repairs what [inspect] found, in one transaction. Returns how many
  /// rows changed.
  Future<Result<int>> fix(MaintenanceTool tool);
}
