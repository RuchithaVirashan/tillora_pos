import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/catalog/department_option.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/non_barcode_item.dart';
import '../../domain/usecases/non_barcode_usecases.dart';

/// Manage Non-Barcode Products: add form and the current keys.
class NonBarcodePanel extends StatefulWidget {
  const NonBarcodePanel({super.key});

  @override
  State<NonBarcodePanel> createState() => _NonBarcodePanelState();
}

class _NonBarcodePanelState extends State<NonBarcodePanel> {
  final _id = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  List<DepartmentOption> _departments = const [];
  DepartmentOption? _department;
  bool _ageRestricted = false;
  List<NonBarcodeItem>? _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _id.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final setup = await getIt<GetNonBarcodeSetup>()();
    final items = await getIt<GetNonBarcodeItems>()();
    if (!mounted) return;
    setState(() {
      if (setup case Ok(value: (final departments, final nextId))) {
        _departments = departments;
        _id.text = '$nextId';
      }
      if (items case Ok(:final value)) _items = value;
    });
  }

  void _clear() {
    _description.clear();
    _price.clear();
    setState(() {
      _department = null;
      _ageRestricted = false;
    });
  }

  Future<void> _add() async {
    setState(() => _saving = true);
    final result = await getIt<AddNonBarcodeItem>()(
      itemId: int.tryParse(_id.text.trim()),
      description: _description.text,
      priceCents: Money.toCents(double.tryParse(_price.text.trim()) ?? 0),
      department: _department,
      ageRestricted: _ageRestricted,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${_description.text.trim()} added');
    _clear();
    _reload();
  }

  Future<void> _delete(NonBarcodeItem item) async {
    final ok = await confirm(context, title: 'Delete item', message: 'Delete ${item.description}?', confirmLabel: 'Delete', destructive: true);
    if (!ok || !mounted) return;
    if (await getIt<DeleteNonBarcodeItem>()(item.itemId) case Err(:final failure)) {
      if (mounted) showToast(context, failure.message, error: true);
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = _items;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        FieldGrid(
          children: [
            LabeledField(label: 'ID', child: TextField(controller: _id, keyboardType: TextInputType.number)),
            LabeledField(label: 'Description', child: TextField(controller: _description, decoration: const InputDecoration(hintText: 'Description'))),
            LabeledField(
              label: 'Price',
              child: TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: 'Rs ', hintText: '0.00 = cashier types the price'),
              ),
            ),
            LabeledField(
              label: 'Department',
              child: DropdownButtonFormField<DepartmentOption>(
                initialValue: _department,
                hint: const Text('Select Department'),
                items: [for (final d in _departments) DropdownMenuItem(value: d, child: Text(d.name))],
                onChanged: (d) => setState(() => _department = d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _ageRestricted,
          onChanged: (v) => setState(() => _ageRestricted = v ?? false),
          title: const Text('Age Refusal'),
          subtitle: Text(
            _department == null || _department!.ageLimit == 0 ? 'Asks for age; uses 18+' : 'Asks for age: ${_department!.ageLimit}+',
            style: TextStyle(color: c.muted),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: PosButton(label: 'Cancel', height: 54, style: PosButtonStyle.secondary, onPressed: _clear)),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: PosButton(label: 'Add', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _saving ? null : _add)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Current items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: c.muted)),
        const SizedBox(height: 8),
        if (items == null)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          Text('No non-barcode items yet.', style: TextStyle(color: c.muted))
        else
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.description, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
              subtitle: Text(
                [
                  '#${item.itemId}',
                  if (item.departmentName.isNotEmpty) item.departmentName,
                  if (item.ageLimit > 0) '${item.ageLimit}+',
                ].join(' · '),
                style: TextStyle(color: c.muted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.priceCents == 0 ? 'Open price' : Money.lkr(Money.fromCents(item.priceCents)),
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
                  IconButton(tooltip: 'Delete', icon: Icon(Icons.delete_outline_rounded, color: c.voidInk), onPressed: () => _delete(item)),
                ],
              ),
            ),
      ],
    );
  }
}
