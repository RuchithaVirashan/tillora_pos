import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../departments/domain/entities/department.dart';
import '../../domain/entities/barcode_product.dart';

/// BOAddBarcode: add / edit a barcode product. [initial] null means new.
class BarcodeProductForm extends StatefulWidget {
  const BarcodeProductForm({super.key, required this.initial, required this.departments, required this.onSave});

  final BarcodeProduct? initial;
  final List<Department> departments;
  final Future<void> Function(BarcodeProduct) onSave;

  @override
  State<BarcodeProductForm> createState() => _BarcodeProductFormState();
}

class _BarcodeProductFormState extends State<BarcodeProductForm> {
  static final _digits = [FilteringTextInputFormatter.digitsOnly];
  static final _decimal = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];

  late final _p = widget.initial;
  late final _barcode = TextEditingController(text: _p?.barcode);
  late final _description = TextEditingController(text: _p?.description);
  late final _secondary = TextEditingController(text: _p?.secondaryBarcode);
  late final _price = TextEditingController(text: _p == null ? '' : _money(_p.priceCents));
  late final _vat = TextEditingController(text: _trim(_p?.vat ?? 0));
  late final _stock = TextEditingController(text: '${_p?.stock ?? 0}');
  late final _age = TextEditingController(text: '${(_p?.ageLimit ?? 0) > 0 ? _p!.ageLimit : 18}');
  late final _caseBarcode = TextEditingController(text: _p?.caseBarcode);
  late final _units = TextEditingController(text: '${_p?.unitsPerCase ?? 1}');
  late final _caseCost = TextEditingController(text: _p == null || _p.costPerCaseCents == 0 ? '' : _money(_p.costPerCaseCents));
  late int? _departmentId = _p?.departmentId;
  late int? _subDepartmentId = _p?.subDepartmentId;
  late bool _ageRestricted = (_p?.ageLimit ?? 0) > 0;
  late bool _quick = _p?.quickItem ?? false;
  bool _saving = false;

  static String _trim(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
  static String _money(int cents) => Money.fromCents(cents).toStringAsFixed(2);
  static int _cents(TextEditingController c) => Money.toCents(double.tryParse(c.text.trim()) ?? 0);

  Department? get _department => widget.departments.where((d) => d.id == _departmentId).firstOrNull;

  @override
  void dispose() {
    for (final c in [_barcode, _description, _secondary, _price, _vat, _stock, _age, _caseBarcode, _units, _caseCost]) {
      c.dispose();
    }
    super.dispose();
  }

  /// A new product takes its VAT and age limit from the department.
  void _pickDepartment(int? id) => setState(() {
    _departmentId = id;
    _subDepartmentId = null;
    final d = _department;
    if (d != null && _p == null) {
      _vat.text = _trim(d.vat);
      _ageRestricted = d.ageLimit > 0;
      if (d.ageLimit > 0) _age.text = '${d.ageLimit}';
    }
  });

  BarcodeProduct _read() => BarcodeProduct(
    id: _p?.id,
    barcode: _barcode.text.trim(),
    description: _description.text,
    priceCents: _cents(_price),
    departmentId: _departmentId,
    subDepartmentId: _subDepartmentId,
    vat: double.tryParse(_vat.text.trim()) ?? -1,
    stock: _p?.stock ?? (int.tryParse(_stock.text.trim()) ?? 0),
    ageLimit: _ageRestricted ? (int.tryParse(_age.text.trim()) ?? -1) : 0,
    secondaryBarcode: _secondary.text.trim(),
    caseBarcode: _caseBarcode.text.trim(),
    unitsPerCase: int.tryParse(_units.text.trim()) ?? 0,
    costPerCaseCents: _cents(_caseCost),
    quickItem: _quick,
    inPromotion: _p?.inPromotion ?? false,
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_read());
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editing = _p != null;
    final preview = _read();
    final subs = _department?.subDepartments ?? const <SubDepartment>[];
    void refresh(String _) => setState(() {});
    return ListView(
      children: [
        Text(editing ? 'Edit Product' : 'Add New Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 16),
        FieldGrid(
          children: [
            LabeledField(
              label: 'Barcode',
              child: TextField(controller: _barcode, autofocus: !editing, inputFormatters: _digits, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Scan or type')),
            ),
            LabeledField(
              label: 'Secondary Barcode',
              child: TextField(controller: _secondary, inputFormatters: _digits, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Optional')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LabeledField(label: 'Description', child: TextField(controller: _description, decoration: const InputDecoration(hintText: 'Product name on the receipt'))),
        const SizedBox(height: 14),
        FieldGrid(
          children: [
            LabeledField(
              label: 'Price',
              child: TextField(controller: _price, inputFormatters: _decimal, onChanged: refresh, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: 'Rs ')),
            ),
            LabeledField(
              label: 'VAT %',
              child: TextField(controller: _vat, inputFormatters: _decimal, onChanged: refresh, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(suffixText: '%')),
            ),
            LabeledField(
              label: 'Department',
              child: DropdownButtonFormField<int>(
                initialValue: _department?.id,
                isExpanded: true,
                hint: const Text('Select'),
                items: [for (final d in widget.departments) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))],
                onChanged: _pickDepartment,
              ),
            ),
            LabeledField(
              label: 'Sub Department',
              child: DropdownButtonFormField<int?>(
                key: ValueKey(_departmentId),
                initialValue: subs.any((s) => s.id == _subDepartmentId) ? _subDepartmentId : null,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final s in subs) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: subs.isEmpty ? null : (v) => setState(() => _subDepartmentId = v),
              ),
            ),
            LabeledField(
              label: editing ? 'Stock' : 'Initial Stock',
              child: editing
                  ? ReadOnlyField('${_p.stock}')
                  : TextField(controller: _stock, inputFormatters: _digits, keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Case', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkSecondary)),
        const SizedBox(height: 8),
        FieldGrid(
          children: [
            LabeledField(
              label: 'Case Barcode',
              child: TextField(controller: _caseBarcode, inputFormatters: _digits, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Optional')),
            ),
            LabeledField(label: 'Units per Case', child: TextField(controller: _units, inputFormatters: _digits, onChanged: refresh, keyboardType: TextInputType.number)),
            LabeledField(
              label: 'Cost per Case',
              child: TextField(controller: _caseCost, inputFormatters: _decimal, onChanged: refresh, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: 'Rs ')),
            ),
            LabeledField(label: 'Cost Price (inc. VAT)', child: ReadOnlyField(Money.lkr(Money.fromCents(preview.costPriceCents)))),
            LabeledField(label: 'Margin', child: ReadOnlyField(Money.lkr(Money.fromCents(preview.marginCents)), emphasis: true)),
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
                  child: TextField(controller: _age, inputFormatters: _digits, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: '+', isDense: true)),
                )
              : null,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _quick,
          onChanged: (v) => setState(() => _quick = v ?? false),
          title: const Text('Quick Item'),
          subtitle: const Text('Show as a tile on the sales screen'),
        ),
        const SizedBox(height: 20),
        PosButton(label: 'Save', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _saving ? null : _save),
      ],
    );
  }
}
