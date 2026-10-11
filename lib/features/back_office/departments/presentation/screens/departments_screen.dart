import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../domain/entities/department.dart';
import '../../domain/usecases/department_usecases.dart';
import '../widgets/department_form.dart';

/// BODepartments.dc.html: Manage Departments.
class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  static const _flag = 'departmentManagerAccess';

  final _allowed = getIt<SessionHolder>().value?.access.can(_flag) ?? false;
  List<Department>? _departments;
  int? _selectedId;
  bool _adding = false;
  bool _confirming = false;

  Department? get _selected => _departments?.where((d) => d.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    if (_allowed) _load();
  }

  Future<void> _load({int? select}) async {
    final result = await getIt<GetDepartments>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _departments = value;
          _selectedId = select ?? (value.any((d) => d.id == _selectedId) ? _selectedId : null);
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _startAdd() => setState(() {
    _adding = true;
    _confirming = false;
  });

  void _select(int? id) => setState(() {
    _selectedId = id;
    _adding = false;
    _confirming = false;
  });

  Future<void> _save(Department department) async {
    final isNew = _adding;
    final result = await getIt<SaveDepartment>()(department, isNew: isNew);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        showToast(context, isNew ? '${department.name.trim()} added' : 'Department updated');
        setState(() => _adding = false);
        _load(select: value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _delete() async {
    final d = _selected!;
    final result = await getIt<DeleteDepartment>()(d);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${d.name} deleted');
    setState(() => _selectedId = null);
    _load();
  }

  Future<void> _addSub(String name) async {
    final result = await getIt<AddSubDepartment>()(_selected!, name);
    if (!mounted) return;
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    _load();
  }

  Future<void> _deleteSub(SubDepartment sub) async {
    if (await getIt<DeleteSubDepartment>()(sub) case Err(:final failure)) {
      if (mounted) showToast(context, failure.message, error: true);
      return;
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · MANAGEMENT',
      title: 'Manage Departments',
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: !_allowed
          ? const NoAccess(what: 'Department Manager')
          : CrudLayout(
              hint: _adding ? 'Adding a new department' : (selected == null ? 'Please select a department to edit or delete' : 'Selected: ${selected.name}'),
              onAdd: _startAdd,
              onEdit: selected == null ? null : () => setState(() => _adding = false),
              onDelete: selected == null ? null : () => setState(() => _confirming = true),
              formOpen: _adding || selected != null,
              onCloseForm: () => setState(() {
                _adding = false;
                _selectedId = null;
                _confirming = false;
              }),
              confirm: _confirming && selected != null
                  ? DeleteConfirm(
                      text: 'Are you sure you want to delete ${selected.name}?',
                      onCancel: () => setState(() => _confirming = false),
                      onDelete: _delete,
                    )
                  : null,
              list: _table(context),
              form: _adding || selected != null
                  ? DepartmentForm(
                      key: ValueKey(_adding ? 'new' : selected!.id),
                      initial: _adding ? null : selected,
                      onSave: _save,
                      onAddSub: _addSub,
                      onDeleteSub: _deleteSub,
                    )
                  : Center(child: Text('Select a department, or tap Add New', style: TextStyle(color: context.colors.muted))),
            ),
    );
  }

  Widget _table(BuildContext context) {
    final c = context.colors;
    final departments = _departments;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    // Phones drop the VAT and Group ID columns.
    final narrow = Breakpoints.of(context) == DeviceClass.phone;
    Widget cols(List<Widget> cells) => Row(
      children: [
        SizedBox(width: 50, child: cells[0]),
        Expanded(child: cells[1]),
        if (!narrow) SizedBox(width: 90, child: cells[2]),
        SizedBox(width: narrow ? 90 : 110, child: Center(child: cells[3])),
        if (!narrow) SizedBox(width: 80, child: cells[4]),
      ],
    );
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: cols([Text('ID', style: head), Text('DEPARTMENT', style: head), Text('VAT', style: head), Text('AGE REFUSAL', style: head), Text('GROUP ID', style: head)]),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: departments == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: departments.length,
                    itemExtent: 54,
                    itemBuilder: (context, i) {
                      final d = departments[i];
                      final on = d.id == _selectedId && !_adding;
                      final body = TextStyle(fontSize: 15, color: c.inkSecondary);
                      return Material(
                        color: on ? c.selection : c.surface,
                        child: InkWell(
                          onTap: () => _select(d.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: c.rowLine),
                                left: BorderSide(color: on ? AppColors.amber : Colors.transparent, width: 4),
                              ),
                            ),
                            child: cols([
                              Text('${d.id}', style: body),
                              Text(d.name, overflow: TextOverflow.ellipsis, style: body.copyWith(fontWeight: FontWeight.w800, color: c.ink)),
                              Text(d.vat == 0 ? 'Exempt' : 'VAT ${_pct(d.vat)}%', style: body),
                              Text(d.ageLimit > 0 ? '${d.ageLimit}+' : 'No', style: body),
                              Text('G${d.groupId}', style: body),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _pct(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
}
