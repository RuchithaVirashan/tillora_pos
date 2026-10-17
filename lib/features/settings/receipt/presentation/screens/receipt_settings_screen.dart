import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/usecases/receipt_settings_usecases.dart';

/// SetReceipt.dc.html: logo, header and footer, with a live preview.
class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  final _header = TextEditingController();
  final _footer = TextEditingController();
  String? _logo;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _header.dispose();
    _footer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<GetReceiptSettings>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _header.text = value.header;
        _footer.text = value.footer;
        setState(() {
          _logo = value.logoPath;
          _loaded = true;
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _pickLogo() async {
    final files = await FilePicker.pickFiles(dialogTitle: 'Select logo', type: FileType.custom, allowedExtensions: SetReceiptLogo.extensions);
    final file = files.firstOrNull;
    if (file == null) return;
    final result = await getIt<SetReceiptLogo>()(await file.readAsBytes(), file.extension ?? '');
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _logo = value);
        showToast(context, 'Logo updated');
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _removeLogo() async {
    final result = await getIt<RemoveReceiptLogo>()();
    if (!mounted) return;
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    setState(() => _logo = null);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await getIt<SaveReceiptText>()(header: _header.text, footer: _footer.text);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showToast(context, 'Receipt updated');
        _load();
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'Receipt',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 900;
                final editor = Panel(child: _editor(context));
                final preview = _Preview(header: _header, footer: _footer, logo: _logo);
                return SingleChildScrollView(
                  padding: EdgeInsets.all(wide ? 26 : 12),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Expanded(child: editor), const SizedBox(width: 24), preview],
                        )
                      : Column(children: [editor, const SizedBox(height: 20), preview]),
                );
              },
            ),
    );
  }

  Widget _editor(BuildContext context) {
    final c = context.colors;
    final logo = _logo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Logo For Header',
          child: Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: c.inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
                padding: const EdgeInsets.all(8),
                child: logo == null
                    ? Icon(Icons.image_outlined, color: c.muted, size: 32)
                    : Image.file(File(logo), fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: c.muted)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PosButton(label: logo == null ? 'Please Select An Image' : 'Change Image', height: 44, style: PosButtonStyle.secondary, onPressed: _pickLogo),
                        if (logo != null) PosButton(label: 'Remove', height: 44, style: PosButtonStyle.voidTint, onPressed: _removeLogo),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Black and white logos print best', style: TextStyle(color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Header',
          child: TextField(controller: _header, minLines: 3, maxLines: 6, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Receipt Header')),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Footer',
          child: TextField(controller: _footer, minLines: 2, maxLines: 5, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Receipt Footer')),
        ),
        const SizedBox(height: 20),
        PosButton(label: 'Update', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _saving ? null : _save),
      ],
    );
  }
}

/// An 80 mm receipt with a sample sale, as it will print.
class _Preview extends StatelessWidget {
  const _Preview({required this.header, required this.footer, required this.logo});

  final TextEditingController header;
  final TextEditingController footer;
  final String? logo;

  static const _sample = [('Fresh Milk 1L', '480.00'), ('Sliced Bread 450g', '180.00'), ('Eggs x10  2 @ 550.00', '1,100.00'), ('Ambul Bananas 1kg', '320.00')];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mono = GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF111111));
    List<String> lines(String text) => [for (final l in text.split('\n')) if (l.trim().isNotEmpty) l.trim()];
    Widget pair(String a, String b, {bool bold = false}) => Row(
      children: [
        Expanded(child: Text(a, style: bold ? mono.copyWith(fontWeight: FontWeight.w800) : mono)),
        Text(b, style: bold ? mono.copyWith(fontWeight: FontWeight.w800) : mono),
      ],
    );
    Widget rule() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text('-' * 34, maxLines: 1, overflow: TextOverflow.clip, style: mono.copyWith(color: const Color(0xFF888888))),
    );
    final head = lines(header.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PREVIEW · 80 MM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.muted)),
        const SizedBox(height: 8),
        Container(
          width: 320,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (logo != null) ...[
                SizedBox(height: 64, child: Image.file(File(logo!), fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink())),
                const SizedBox(height: 6),
              ],
              for (final (i, l) in head.indexed)
                Text(l, textAlign: TextAlign.center, style: i == 0 ? mono.copyWith(fontSize: 15, fontWeight: FontWeight.w800) : mono),
              rule(),
              pair('#000123', '11/10/2026 10:42'),
              rule(),
              for (final (name, amount) in _sample) pair(name, amount),
              rule(),
              pair('TOTAL', 'Rs 2,080.00', bold: true),
              pair('Cash', '2,500.00'),
              pair('Change', '420.00'),
              rule(),
              for (final l in lines(footer.text)) Text(l, textAlign: TextAlign.center, style: mono),
            ],
          ),
        ),
      ],
    );
  }
}
