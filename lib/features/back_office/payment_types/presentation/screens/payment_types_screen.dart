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
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/payment_type_admin_repository.dart';
import '../../domain/usecases/payment_type_admin_usecases.dart';

/// BOPaymentTypes.dc.html: Manage Payment Types.
class PaymentTypesScreen extends StatefulWidget {
  const PaymentTypesScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<PaymentTypesScreen> createState() => _PaymentTypesScreenState();
}

class _PaymentTypesScreenState extends State<PaymentTypesScreen> {
  static const _flag = 'paymentTypeManagerAccess';

  final _allowed = getIt<SessionHolder>().value?.access.can(_flag) ?? false;
  List<ManagedPaymentType>? _types;
  int? _selectedId;
  bool _adding = false;
  bool _confirming = false;

  ManagedPaymentType? get _selected => _types?.where((t) => t.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    if (_allowed) _load();
  }

  Future<void> _load({int? select}) async {
    final result = await getIt<GetManagedPaymentTypes>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _types = value;
          _selectedId = select ?? (value.any((t) => t.id == _selectedId) ? _selectedId : null);
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _startAdd() => setState(() {
    _adding = true;
    _confirming = false;
  });

  void _select(int id) => setState(() {
    _selectedId = id;
    _adding = false;
    _confirming = false;
  });

  Future<void> _save(String name, bool enabled) async {
    final existing = _adding ? null : _selected;
    final result = await getIt<SavePaymentType>()(existing: existing, name: name, enabled: enabled, all: _types ?? const []);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        showToast(context, existing == null ? '${name.trim()} added' : 'Payment type updated');
        setState(() => _adding = false);
        _load(select: value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _delete() async {
    final type = _selected!;
    final result = await getIt<DeletePaymentType>()(type);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${type.name} deleted');
    setState(() => _selectedId = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · MANAGEMENT',
      title: 'Manage Payment Types',
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: !_allowed
          ? const NoAccess(what: 'Payment Type Manager')
          : CrudLayout(
              hint: _adding ? 'Adding a new payment type' : (selected == null ? 'Please select an item to edit or delete' : 'Selected: ${selected.name}'),
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
              list: _grid(context),
              form: _adding || selected != null
                  ? _PaymentTypeForm(key: ValueKey(_adding ? 'new' : selected!.id), initial: _adding ? null : selected, onSave: _save)
                  : Center(child: Text('Select a payment type, or tap Add New', style: TextStyle(color: context.colors.muted))),
            ),
    );
  }

  Widget _grid(BuildContext context) {
    final c = context.colors;
    final types = _types;
    if (types == null) return const Center(child: CircularProgressIndicator());
    if (types.isEmpty) return Center(child: Text('No payment types yet', style: TextStyle(color: c.muted)));
    final columns = switch (Breakpoints.of(context)) {
      DeviceClass.phone => 2,
      _ => 3,
    };
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 130),
      itemCount: types.length,
      itemBuilder: (context, i) {
        final t = types[i];
        final on = t.id == _selectedId && !_adding;
        return Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: on ? c.primary : c.line, width: on ? 2 : 1)),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _select(t.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 56,
                    height: 40,
                    decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.payments_outlined, color: c.muted),
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(t.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink))),
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: t.enabled ? AppColors.successTint : c.background, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          t.enabled ? 'Enabled' : 'Disabled',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.enabled ? AppColors.successInk : c.inkSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaymentTypeForm extends StatefulWidget {
  const _PaymentTypeForm({super.key, required this.initial, required this.onSave});

  final ManagedPaymentType? initial;
  final Future<void> Function(String name, bool enabled) onSave;

  @override
  State<_PaymentTypeForm> createState() => _PaymentTypeFormState();
}

class _PaymentTypeFormState extends State<_PaymentTypeForm> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late bool _enabled = widget.initial?.enabled ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_name.text, _enabled);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editing = widget.initial != null;
    return ListView(
      children: [
        Text(editing ? 'Edit Payment Type' : 'Add New Payment Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 16),
        LabeledField(label: 'Payment Type Name', child: TextField(controller: _name, autofocus: !editing, decoration: const InputDecoration(hintText: 'Payment Type Name'))),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _enabled,
          activeTrackColor: AppColors.success,
          onChanged: (v) => setState(() => _enabled = v),
          title: const Text('Enable Payment Type'),
          subtitle: Text('Enabled types show on the Other Payment screen.', style: TextStyle(color: c.muted)),
        ),
        const SizedBox(height: 16),
        PosButton(
          label: editing ? 'Update' : 'Add Payment Type',
          height: 54,
          fontSize: 16,
          style: PosButtonStyle.primary,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
