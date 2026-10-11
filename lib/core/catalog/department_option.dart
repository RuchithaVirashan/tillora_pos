import 'package:equatable/equatable.dart';

/// A department as offered in product forms.
class DepartmentOption extends Equatable {
  const DepartmentOption({required this.id, required this.name, this.vat = 0, this.ageLimit = 0});

  final int id;
  final String name;
  final double vat;

  /// Minimum customer age for the department; 0 when unrestricted.
  final int ageLimit;

  static DepartmentOption fromRow(Map<String, Object?> r) => DepartmentOption(
    id: r['id'] as int,
    name: r['name'] as String,
    vat: (r['vat'] as num?)?.toDouble() ?? 0,
    ageLimit: (r['ageRefusal'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [id];
}
