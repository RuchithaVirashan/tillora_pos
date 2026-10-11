import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/module_scaffold.dart';
import '../../../../core/widgets/pos_button.dart';
import '../../domain/entities/supplier.dart';

/// Add or edit a supplier. [initial] null means a new supplier.
class SupplierForm extends StatefulWidget {
  const SupplierForm({super.key, required this.initial, required this.onCancel, required this.onSave});

  final Supplier? initial;
  final VoidCallback onCancel;
  final Future<void> Function(Supplier supplier) onSave;

  @override
  State<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<SupplierForm> {
  static const _defaultCountry = 'Sri Lanka';

  late final _name = TextEditingController(text: widget.initial?.name);
  late final _number = TextEditingController(text: widget.initial?.address.number);
  late final _street = TextEditingController(text: widget.initial?.address.street);
  late final _country = TextEditingController(
    text: (widget.initial?.address.country.isNotEmpty ?? false) ? widget.initial!.address.country : _defaultCountry,
  );
  late final _districtText = TextEditingController(text: widget.initial?.address.district);
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '+94 ');
  late final _email = TextEditingController(text: widget.initial?.email);
  late String? _district = sriLankaDistricts.contains(widget.initial?.address.district) ? widget.initial!.address.district : null;
  bool _saving = false;

  bool get _sriLanka => _country.text.trim().toLowerCase() == _defaultCountry.toLowerCase();

  @override
  void dispose() {
    for (final c in [_name, _number, _street, _country, _districtText, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await widget.onSave(Supplier(
      id: widget.initial?.id,
      name: _name.text,
      address: SupplierAddress(
        number: _number.text,
        street: _street.text,
        district: _sriLanka ? (_district ?? '') : _districtText.text,
        country: _country.text,
      ),
      phone: _phone.text,
      email: _email.text,
    ));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editing = widget.initial != null;
    return ListView(
      children: [
        Text(editing ? 'Edit Supplier Details' : 'Add New Supplier Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 18),
        LabeledField(label: 'Name', child: TextField(controller: _name, autofocus: true, decoration: const InputDecoration(hintText: 'Name'))),
        const SizedBox(height: 14),
        FieldGrid(
          children: [
            LabeledField(label: 'No', child: TextField(controller: _number, decoration: const InputDecoration(hintText: 'No'))),
            LabeledField(label: 'Street, Road, Town', child: TextField(controller: _street, decoration: const InputDecoration(hintText: 'Street, Road, Town'))),
            LabeledField(
              label: 'Country',
              child: TextField(controller: _country, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Country')),
            ),
            LabeledField(
              label: 'District',
              child: _sriLanka
                  ? DropdownButtonFormField<String>(
                      initialValue: _district,
                      hint: const Text('Please select address district'),
                      items: [for (final d in sriLankaDistricts) DropdownMenuItem(value: d, child: Text(d))],
                      onChanged: (v) => setState(() => _district = v),
                    )
                  : TextField(controller: _districtText, decoration: const InputDecoration(hintText: 'District / region')),
            ),
            LabeledField(
              label: 'Mobile Number',
              child: TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+94 7X XXX XXXX')),
            ),
            LabeledField(
              label: 'Email',
              child: TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email')),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: PosButton(label: 'Cancel', height: 54, style: PosButtonStyle.secondary, onPressed: widget.onCancel)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PosButton(
                label: editing ? 'Save Changes' : 'Add Supplier',
                height: 54,
                fontSize: 16,
                style: PosButtonStyle.primary,
                onPressed: _saving ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
