import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/catalog/department_option.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/weight_items_repository.dart';
import '../../domain/usecases/weight_items_usecases.dart';

/// Add Weight Products: price per kg, sold from the Weight key on the till.
class WeightItemsPanel extends StatefulWidget {
  const WeightItemsPanel({super.key});

  @override
  State<WeightItemsPanel> createState() => _WeightItemsPanelState();
}

class _WeightItemsPanelState extends State<WeightItemsPanel> {
  final _code = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  List<DepartmentOption> _departments = const [];
  DepartmentOption? _department;
  bool _ageRestricted = false;
  List<WeightProduct>? _products;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    getIt<GetWeightDepartments>()().then((r) {
      if (r case Ok(:final value) when mounted) setState(() => _departments = value);
    });
    _reload();
  }

  @override
  void dispose() {
    _code.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final result = await getIt<GetWeightProducts>()();
    if (result case Ok(:final value) when mounted) setState(() => _products = value);
  }

  void _clear() {
    _code.clear();
    _description.clear();
    _price.clear();
    setState(() {
      _department = null;
      _ageRestricted = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await getIt<AddWeightProduct>()(
      code: _code.text,
      description: _description.text,
      pricePerKgCents: Money.toCents(double.tryParse(_price.text.trim()) ?? 0),
      department: _department,
      ageRestricted: _ageRestricted,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${_description.text.trim()} saved');
    _clear();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final products = _products;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        FieldGrid(
          children: [
            LabeledField(
              label: 'Code',
              child: TextField(controller: _code, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Item Code')),
            ),
            LabeledField(label: 'Description', child: TextField(controller: _description, decoration: const InputDecoration(hintText: 'Item Description'))),
            LabeledField(
              label: 'Price per kg',
              child: TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: 'Rs ', hintText: 'Item Price'),
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
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: PosButton(label: 'Cancel', height: 54, style: PosButtonStyle.secondary, onPressed: _clear)),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: PosButton(label: 'Save', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _saving ? null : _save)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Weight products', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: c.muted)),
        const SizedBox(height: 8),
        if (products == null)
          const Center(child: CircularProgressIndicator())
        else if (products.isEmpty)
          Text('No weight products yet.', style: TextStyle(color: c.muted))
        else
          for (final p in products)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.description, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
              subtitle: Text([p.code, if (p.departmentName.isNotEmpty) p.departmentName].join(' · '), style: TextStyle(color: c.muted)),
              trailing: Text('${Money.lkr(Money.fromCents(p.pricePerKgCents))} / kg',
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
            ),
      ],
    );
  }
}
