import 'package:equatable/equatable.dart';

class SubDepartment extends Equatable {
  const SubDepartment({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class Department extends Equatable {
  const Department({
    this.id,
    required this.name,
    this.vat = 0,
    this.ageLimit = 0,
    this.groupId = 1,
    this.quickMenu = true,
    this.subDepartments = const [],
  });

  /// Null until saved (or when the ID is left for the till to choose).
  final int? id;
  final String name;

  /// Percent, e.g. 18 for 18%.
  final double vat;

  /// Minimum customer age; 0 when unrestricted.
  final int ageLimit;
  final int groupId;

  /// Shown as a quick department on the sales screen.
  final bool quickMenu;
  final List<SubDepartment> subDepartments;

  @override
  List<Object?> get props => [id, name, vat, ageLimit, groupId, quickMenu, subDepartments];
}
