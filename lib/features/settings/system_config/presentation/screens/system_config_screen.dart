import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/side_nav_layout.dart';
import '../../domain/entities/system_settings.dart';
import '../../domain/usecases/system_settings_usecases.dart';

/// SetSystemConfig.dc.html: till, printer and sales options.
/// [onOpenRoleAccess] opens User Access Control.
class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key, required this.onBack, required this.onOpenRoleAccess});

  final VoidCallback onBack;
  final VoidCallback onOpenRoleAccess;

  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

enum _Section {
  till('Till Configuration'),
  printer('Printer Configuration'),
  optional('Optional Settings'),
  currency('Currency Configuration'),
  access('User Access Control');

  const _Section(this.label);
  final String label;
}

class _SystemConfigScreenState extends State<SystemConfigScreen> {
  final _terminal = TextEditingController();
  final _maxQty = TextEditingController();
  _Section _section = _Section.till;
  SystemSettings? _settings;
  List<String>? _printers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrinters();
  }

  @override
  void dispose() {
    _terminal.dispose();
    _maxQty.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<GetSystemSettings>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _terminal.text = value.terminalName;
        _maxQty.text = '${value.maxQuantity}';
        setState(() => _settings = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _loadPrinters() async {
    final result = await getIt<GetInstalledPrinters>()();
    if (!mounted) return;
    setState(() => _printers = switch (result) {
      Ok(:final value) => value,
      Err() => const [],
    });
  }

  void _edit(SystemSettings Function(SystemSettings s) change) => setState(() => _settings = change(_settings!));

  Future<void> _save() async {
    final s = _settings!.copyWith(terminalName: _terminal.text, maxQuantity: int.tryParse(_maxQty.text.trim()) ?? 0);
    setState(() => _saving = true);
    final result = await getIt<SaveSystemSettings>()(s);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showToast(context, 'System configuration updated');
        _load();
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'System Configuration',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : SideNavLayout(
              items: [
                for (final section in _Section.values)
                  SideNavItem(section.label, onOpen: section == _Section.access ? widget.onOpenRoleAccess : null),
              ],
              selected: _section.index,
              onSelect: (i) => setState(() => _section = _Section.values[i]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_section.label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.colors.ink)),
                  const SizedBox(height: 16),
                  ...switch (_section) {
                    _Section.till => _till(context),
                    _Section.printer => _printer(context, s),
                    _Section.optional => _optional(s),
                    _Section.currency || _Section.access => _currency(context),
                  },
                  if (_section != _Section.currency) ...[
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PosButton(label: 'Update', height: 52, style: PosButtonStyle.primary, onPressed: _saving ? null : _save),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  List<Widget> _till(BuildContext context) => [
    FieldGrid(
      children: [
        LabeledField(label: 'Terminal Name', child: TextField(controller: _terminal, decoration: const InputDecoration(hintText: 'POS-01'))),
        LabeledField(
          label: 'Maximum Quantity Per Line',
          child: TextField(controller: _maxQty, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ),
      ],
    ),
    const SizedBox(height: 10),
    Text('The terminal name prints on receipts and reports. Changes apply the next time Sales opens.', style: TextStyle(color: context.colors.muted)),
  ];

  List<Widget> _printer(BuildContext context, SystemSettings s) {
    final c = context.colors;
    final printers = _printers;
    Widget picker(String label, String? value, ValueChanged<String?> onChanged, String note) {
      // A saved printer that is not installed now still shows, so it is
      // not silently replaced.
      final names = {...?printers, ?value}.toList()..sort();
      return LabeledField(
        label: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String?>(
              key: ValueKey('$label-${names.length}'),
              initialValue: value,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('System default printer')),
                for (final n in names) DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: printers == null ? null : onChanged,
            ),
            const SizedBox(height: 4),
            Text(note, style: TextStyle(color: c.muted)),
          ],
        ),
      );
    }

    return [
      picker('Receipt Printer', s.receiptPrinter, (v) => _edit((s) => s.copyWith(receiptPrinter: () => v)), 'Receipts and till roll reports print here, and the cash drawer opens through it.'),
      const SizedBox(height: 16),
      LabeledField(
        label: 'Printer Paper Size',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mm in getIt<GetInstalledPrinters>().paperWidths)
              ChoiceChip(label: Text('$mm mm'), selected: s.paperWidthMm == mm, onSelected: (_) => _edit((s) => s.copyWith(paperWidthMm: mm))),
          ],
        ),
      ),
      const SizedBox(height: 16),
      picker('Label Printer', s.labelPrinter, (v) => _edit((s) => s.copyWith(labelPrinter: () => v)), 'Print In QL from Label Printer uses this printer.'),
      if (printers != null && printers.isEmpty) ...[
        const SizedBox(height: 10),
        Text('No printers were found on this computer.', style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700)),
      ],
    ];
  }

  List<Widget> _optional(SystemSettings s) => [
    SettingSwitch(
      label: 'Auto Print Receipts',
      note: 'Print a receipt at the end of every sale',
      value: s.autoPrint,
      onChanged: (v) => _edit((s) => s.copyWith(autoPrint: v)),
    ),
    SettingSwitch(
      label: 'Enable Card Payments',
      note: 'The CARD key takes payments',
      value: s.cardPayments,
      onChanged: (v) => _edit((s) => s.copyWith(cardPayments: v)),
    ),
    SettingSwitch(
      label: 'Enable Age Refusal',
      note: 'Ask the cashier to check age for restricted items',
      value: s.ageCheck,
      onChanged: (v) => _edit((s) => s.copyWith(ageCheck: v)),
    ),
    SettingSwitch(
      label: 'Night Theme for Sales',
      note: 'A dark sales screen, easier on the eyes in dim shops',
      value: s.nightTheme,
      onChanged: (v) => _edit((s) => s.copyWith(nightTheme: v)),
    ),
  ];

  List<Widget> _currency(BuildContext context) {
    final c = context.colors;
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.selection, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Text('Rs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.primary)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sri Lankan Rupee (LKR)', style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                  Text('Shown as Rs 1,250.00', style: TextStyle(color: c.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text('Tillora works in Sri Lankan Rupees.', style: TextStyle(color: c.muted)),
    ];
  }
}
