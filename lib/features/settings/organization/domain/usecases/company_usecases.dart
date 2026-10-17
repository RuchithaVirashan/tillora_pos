import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/company_details.dart';
import '../repositories/company_repository.dart';

class GetCompanyDetails {
  const GetCompanyDetails(this._repository);
  final CompanyRepository _repository;

  Future<Result<CompanyDetails>> call() => _repository.details();
}

class SaveCompanyDetails {
  const SaveCompanyDetails(this._repository);
  final CompanyRepository _repository;

  Future<Result<void>> call(CompanyDetails d) {
    String t(String v) => v.trim();
    if (t(d.name).isEmpty) return Future.value(const Err(ValidationFailure('Enter the company name')));
    return _repository.save(CompanyDetails(
      name: t(d.name),
      address1: t(d.address1),
      address2: t(d.address2),
      phone: t(d.phone),
      phone2: t(d.phone2),
      vatNo: t(d.vatNo),
    ));
  }
}
