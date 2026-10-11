import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/department.dart';

/// Add / edit a department. [initial] null means a new department.
class DepartmentForm extends StatefulWidget {
  const DepartmentForm({super.key, required this.initial, required this.onSave, required this.onAddSub, required this.onDeleteSub});

  final Department? initial;
  final Future<void> Function(Department) onSave;
  final Future<void> Function(String name) onAddSub;
  final Future<void> Function(SubDepartment) onDeleteSub;

  @override
  State<DepartmentForm> createState() => _DepartmentFormState();
}

class _DepartmentFormState extends State<DepartmentForm> {
  late final _d = widget.initial;
  late final _id = TextEditingController(text: _d?.id?.toString());
  late final _name = TextEditingController(text: _d?.name);
  late final _vat = TextEditingController(text: _d == null ? '0' : _trim(_d.vat));
  late final _group = TextEditingController(text: '${_d?.groupId ?? 1}');
  late final _age = TextEditingController(text: '${(_d?.ageLimit ?? 0) > 0 ? _d!.ageLimit : 18}');
  late bool _ageRestricted = (_d?.ageLimit ?? 0) > 0;
  late bool _quick = _d?.quickMenu ?? true;
  final _sub = TextEditingController();
  bool _saving = false;

  static String _trim(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

  @override
  void dispose() {
    for (final c in [_id, _name, _vat, _group, _age, _sub]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(Department(
      id: _d?.id ?? int.tryParse(_id.text.trim()),
      name: _name.text,
      vat: double.tryParse(_vat.text.trim()) ?? -1,
      ageLimit: _ageRestricted ? (int.tryParse(_age.text.trim()) ?? -1) : 0,
      groupId: int.tryParse(_group.text.trim()) ?? 0,
      quickMenu: _quick,
    ));
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _addSub() async {
    await widget.onAddSub(_sub.text);
    _sub.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editing = _d != null;
    return ListView(
      children: [
        Text(editing ? 'Edit Department' : 'Add New Department', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 16),
        FieldGrid(
          children: [
            LabeledField(
              label: 'ID',
              child: editing
                  ? ReadOnlyField('${_d.id}')
                  : TextField(controller: _id, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Auto if blank')),
            ),
            LabeledField(label: 'Department', child: TextField(controller: _name, decoration: const InputDecoration(hintText: 'Department Name'))),
            LabeledField(
              label: 'VAT %',
              child: TextField(controller: _vat, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(suffixText: '%')),
            ),
            LabeledField(label: 'Group ID', child: TextField(controller: _group, keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _ageRestricted,
          onChanged: (v) => setState(() => _ageRestricted = v ?? false),
          title: const Text('Age Refusal'),
          secondary: _ageRestricted
              ? SizedBox(
                  width: 110,
                  child: TextField(controller: _age, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: '+', isDense: true)),
                )
              : null,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _quick,
          onChanged: (v) => setState(() => _quick = v ?? false),
          title: const Text('Add Quick Menu'),
        ),
        if (editing) ...[
          const SizedBox(height: 8),
          Text('Sub Departments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_d.subDepartments.isEmpty) Text('None yet', style: TextStyle(color: c.muted)),
              for (final s in _d.subDepartments)
                InputChip(label: Text(s.name), deleteButtonTooltipMessage: 'Delete ${s.name}', onDeleted: () => widget.onDeleteSub(s)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(controller: _sub, onSubmitted: (_) => _addSub(), decoration: const InputDecoration(hintText: 'New sub department', isDense: true)),
              ),
              const SizedBox(width: 8),
              PosButton(label: '+ Add', height: 48, style: PosButtonStyle.secondary, onPressed: _addSub),
            ],
          ),
        ],
        const SizedBox(height: 20),
        PosButton(label: 'Save', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _saving ? null : _save),
      ],
    );
  }
}
