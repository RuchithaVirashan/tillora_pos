import 'package:equatable/equatable.dart';

/// The shop, printed on receipts and reports.
class CompanyDetails extends Equatable {
  const CompanyDetails({
    required this.name,
    this.address1 = '',
    this.address2 = '',
    this.phone = '',
    this.phone2 = '',
    this.vatNo = '',
  });

  final String name;
  final String address1;
  final String address2;
  final String phone;
  final String phone2;
  final String vatNo;

  static const empty = CompanyDetails(name: '');

  @override
  List<Object?> get props => [name, address1, address2, phone, phone2, vatNo];
}
