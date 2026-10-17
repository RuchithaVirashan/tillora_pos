import '../../../../../core/errors/result.dart';
import '../entities/company_details.dart';

abstract interface class CompanyRepository {
  Future<Result<CompanyDetails>> details();

  /// Saves the details and shows the new name on the till straight away.
  Future<Result<void>> save(CompanyDetails details);
}
