import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../domain/entities/department.dart';
import '../../domain/repositories/department_repository.dart';

class DepartmentRepositoryImpl implements DepartmentRepository {
  DepartmentRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<Department>>> departments() => _guard(() async {
    final rows = await _db.query('departments', orderBy: 'id');
    final subs = await _db.query('subDepartments', columns: ['id', 'name', 'deptId'], orderBy: 'name');
    final byDept = <int, List<SubDepartment>>{};
    for (final s in subs) {
      byDept.putIfAbsent(s['deptId'] as int, () => []).add(SubDepartment(id: s['id'] as int, name: s['name'] as String));
    }
    return [
      for (final r in rows)
        Department(
          id: r['id'] as int,
          name: r['name'] as String,
          vat: (r['vat'] as num).toDouble(),
          ageLimit: (r['ageRefusal'] as num?)?.toInt() ?? 0,
          groupId: (r['groupId'] as num?)?.toInt() ?? 1,
          quickMenu: r['isQuickdept'] == 1,
          subDepartments: byDept[r['id']] ?? const [],
        ),
    ];
  });

  @override
  Future<Result<bool>> idExists(int id) => _guard(() async {
    return (await _db.query('departments', columns: ['id'], where: 'id = ?', whereArgs: [id], limit: 1)).isNotEmpty;
  });

  @override
  Future<Result<int>> save(Department d, {required bool isNew}) => _guard(() async {
    final values = {
      'name': d.name,
      'vat': d.vat,
      'ageRefusal': d.ageLimit,
      'groupId': d.groupId,
      'isQuickdept': d.quickMenu ? 1 : 0,
      'cloudSync': 0,
    };
    if (isNew) return _db.insert('departments', {'id': ?d.id, ...values});
    await _db.update('departments', values, where: 'id = ?', whereArgs: [d.id]);
    return d.id!;
  });

  @override
  Future<Result<int>> usageCount(int id) => _guard(() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM products WHERE departmentId = ?1',
      [id],
    );
    return rows.first['n'] as int;
  });

  /// Removes the department and its sub-departments together.
  @override
  Future<Result<void>> delete(int id) => _guard(() => _db.transaction((txn) async {
    await txn.delete('subDepartments', where: 'deptId = ?', whereArgs: [id]);
    await txn.delete('departments', where: 'id = ?', whereArgs: [id]);
  }));

  @override
  Future<Result<void>> addSubDepartment(int departmentId, String name) => _guard(() async {
    final dept = (await _db.query('departments', columns: ['ageRefusal', 'groupId'], where: 'id = ?', whereArgs: [departmentId])).first;
    await _db.insert('subDepartments', {
      'name': name,
      'deptId': departmentId,
      'isQuickdept': 0,
      'ageRefusal': dept['ageRefusal'],
      'groupId': dept['groupId'],
    });
  });

  @override
  Future<Result<void>> deleteSubDepartment(int subDepartmentId) =>
      _guard(() => _db.delete('subDepartments', where: 'id = ?', whereArgs: [subDepartmentId]));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
