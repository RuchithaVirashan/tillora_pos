import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/company_details.dart';
import '../../domain/usecases/company_usecases.dart';

/// SetOrganization.dc.html: company details, locked until Edit.
class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final _name = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _phone = TextEditingController();
  final _phone2 = TextEditingController();
  final _vat = TextEditingController();
  CompanyDetails _saved = CompanyDetails.empty;
  bool _loaded = false;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _address1, _address2, _phone, _phone2, _vat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<GetCompanyDetails>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _saved = value;
        _fill(value);
        setState(() => _loaded = true);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _fill(CompanyDetails d) {
    _name.text = d.name;
    _address1.text = d.address1;
    _address2.text = d.address2;
    _phone.text = d.phone;
    _phone2.text = d.phone2;
    _vat.text = d.vatNo;
  }

  void _cancel() => setState(() {
    _fill(_saved);
    _editing = false;
  });

  Future<void> _save() async {
    setState(() => _saving = true);
    final details = CompanyDetails(name: _name.text, address1: _address1.text, address2: _address2.text, phone: _phone.text, phone2: _phone2.text, vatNo: _vat.text);
    final result = await getIt<SaveCompanyDetails>()(details);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showToast(context, 'Company Details Updated Successfully');
        _load();
        setState(() => _editing = false);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Widget _field(String label, TextEditingController c, String hint, {TextInputType? keyboard}) => LabeledField(
    label: label,
    child: TextField(controller: c, readOnly: !_editing, keyboardType: keyboard, decoration: InputDecoration(hintText: hint)),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'Setup Organization',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Company details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
                                  Text('Printed on receipts and reports', style: TextStyle(color: c.muted)),
                                ],
                              ),
                            ),
                            if (!_editing) PosButton(label: 'Edit', icon: Icons.edit_outlined, height: 46, style: PosButtonStyle.secondary, onPressed: () => setState(() => _editing = true)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _field('Company Name', _name, 'Company Name'),
                        const SizedBox(height: 14),
                        _field('Address Line 1', _address1, 'Address Line 1'),
                        const SizedBox(height: 14),
                        _field('Address Line 2', _address2, 'Address Line 2'),
                        const SizedBox(height: 14),
                        FieldGrid(
                          children: [
                            _field('Primary Phone', _phone, 'Phone Number 1', keyboard: TextInputType.phone),
                            _field('Secondary Phone', _phone2, 'Phone Number 2', keyboard: TextInputType.phone),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _field('Vat Number', _vat, 'Vat Number'),
                        if (_editing) ...[
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(child: PosButton(label: 'Cancel', height: 52, style: PosButtonStyle.secondary, onPressed: _saving ? null : _cancel)),
                              const SizedBox(width: 10),
                              Expanded(child: PosButton(label: 'Save', height: 52, style: PosButtonStyle.primary, onPressed: _saving ? null : _save)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
