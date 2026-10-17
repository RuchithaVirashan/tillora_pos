import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/customer_display.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/side_nav_layout.dart';
import '../../../../sales/more_functions/domain/usecases/set_auto_print.dart';
import '../../domain/usecases/display_settings_usecases.dart';

/// SetSecondScreen.dc.html: the customer display. Changes show on an open
/// display straight away.
class SecondScreenSettingsScreen extends StatefulWidget {
  const SecondScreenSettingsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SecondScreenSettingsScreen> createState() => _SecondScreenSettingsScreenState();
}

enum _Section {
  display('Customer Display'),
  advert('Advertisement'),
  font('Font Configuration'),
  split('Display Split Ratio');

  const _Section(this.label);
  final String label;
}

class _SecondScreenSettingsScreenState extends State<SecondScreenSettingsScreen> {
  final _seconds = TextEditingController();
  final _supported = getIt<CustomerDisplay>().isSupported;
  _Section _section = _Section.display;
  bool? _enabled;
  DisplayStyle _style = const DisplayStyle();
  final _picked = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _seconds.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<GetDisplaySettings>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _seconds.text = '${value.style.advertSeconds}';
        setState(() {
          _enabled = value.enabled;
          _style = value.style;
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _setEnabled(bool on) => _run(() async {
    final result = await getIt<SetCustomerDisplay>()(on);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _enabled = on);
        showToast(context, on ? 'Customer display turned on' : 'Customer display turned off');
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  });

  Future<void> _saveStyle(DisplayStyle style, String done) => _run(() async {
    final result = await getIt<SaveDisplayStyle>()(style);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _style = style);
        showToast(context, done);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  });

  DisplayStyle _with({int? seconds, int? fontSize, DisplaySplit? split}) => DisplayStyle(
    adverts: _style.adverts,
    advertSeconds: seconds ?? _style.advertSeconds,
    fontSize: fontSize ?? _style.fontSize,
    split: split ?? _style.split,
  );

  Future<void> _addAdvert() async {
    final files = await FilePicker.pickFiles(dialogTitle: 'Select advert image', type: FileType.custom, allowedExtensions: AddAdvert.extensions);
    final file = files.firstOrNull;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _run(() async {
      final result = await getIt<AddAdvert>()(_style, bytes, file.extension ?? '');
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          setState(() => _style = value);
          showToast(context, 'Advert added');
        case Err(:final failure):
          showToast(context, failure.message, error: true);
      }
    });
  }

  Future<void> _deleteAdverts() async {
    final ok = await confirm(
      context,
      title: 'Delete adverts?',
      message: 'Delete ${_picked.length} selected ${_picked.length == 1 ? 'image' : 'images'} from the customer display?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final result = await getIt<RemoveAdverts>()(_style, Set.of(_picked));
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          setState(() {
            _style = value;
            _picked.clear();
          });
          showToast(context, 'Adverts deleted');
        case Err(:final failure):
          showToast(context, failure.message, error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'Second Screen',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: enabled == null
          ? const Center(child: CircularProgressIndicator())
          : SideNavLayout(
              navWidth: 260,
              items: [for (final s in _Section.values) SideNavItem(s.label)],
              selected: _section.index,
              onSelect: (i) => setState(() => _section = _Section.values[i]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_section.label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.colors.ink)),
                  const SizedBox(height: 16),
                  ...switch (_section) {
                    _Section.display => _display(context, enabled),
                    _Section.advert => _adverts(context),
                    _Section.font => _font(context),
                    _Section.split => _split(context),
                  },
                ],
              ),
            ),
    );
  }

  List<Widget> _display(BuildContext context, bool enabled) {
    final c = context.colors;
    return [
      SettingSwitch(
        label: 'Enable Customer Display',
        note: _supported ? 'Opens a second window for customers when Sales opens' : 'This device has no second screen',
        value: enabled,
        onChanged: !_supported || _busy ? null : _setEnabled,
      ),
      const SizedBox(height: 6),
      Text('Move the customer display window onto the second monitor facing the customer.', style: TextStyle(color: c.muted)),
    ];
  }

  List<Widget> _adverts(BuildContext context) {
    final c = context.colors;
    final adverts = _style.adverts;
    return [
      if (adverts.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: c.inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
          child: Text('No adverts yet. The display shows the shop name until you add images.', textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
        )
      else
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final path in adverts)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _picked.contains(path) ? _picked.remove(path) : _picked.add(path)),
                child: Container(
                  width: 200,
                  height: 130,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _picked.contains(path) ? c.primary : c.line, width: _picked.contains(path) ? 3 : 1),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: c.muted)),
                      if (_picked.contains(path))
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Selected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      const SizedBox(height: 18),
      SizedBox(
        width: 220,
        child: LabeledField(
          label: 'Image Duration',
          child: TextField(
            controller: _seconds,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(suffixText: 'sec'),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          PosButton(label: 'Add New', icon: Icons.add_photo_alternate_outlined, height: 50, style: PosButtonStyle.secondary, onPressed: _busy ? null : _addAdvert),
          PosButton(label: 'Delete', height: 50, style: PosButtonStyle.voidTint, onPressed: _picked.isEmpty || _busy ? null : _deleteAdverts),
          PosButton(
            label: 'Update',
            height: 50,
            style: PosButtonStyle.primary,
            onPressed: _busy ? null : () => _saveStyle(_with(seconds: int.tryParse(_seconds.text.trim()) ?? 0), 'Image duration updated'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _font(BuildContext context) {
    final c = context.colors;
    return [
      LabeledField(
        label: 'Font Size',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in DisplayStyle.fontSizes)
              ChoiceChip(
                label: Text('$size${size == DisplayStyle.defaultFontSize ? ' (standard)' : ''}'),
                selected: _style.fontSize == size,
                onSelected: _busy ? null : (_) => _saveStyle(_with(fontSize: size), 'Font size set to $size'),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Text('FONT PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.muted)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Text('Fresh Milk 1L', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17 * _style.textScale, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Total Rs 2,080.00', style: TextStyle(fontSize: 22 * _style.textScale, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _split(BuildContext context) {
    final c = context.colors;
    return [
      Text('Select Display Split Ratio', style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final s in DisplaySplit.values)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _busy ? null : () => _saveStyle(_with(split: s), 'Split set to ${s.label}'),
              child: Container(
                width: 170,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _style.split == s ? c.primary : c.line, width: _style.split == s ? 2 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 54,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: s.left, child: Container(decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(6)))),
                          const SizedBox(width: 4),
                          Expanded(flex: s.right, child: Container(decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(6)))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(s.label, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                  ],
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Text('Left = advertisement, right = basket and totals.', style: TextStyle(color: c.muted)),
    ];
  }
}
