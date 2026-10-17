import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/usecases/promotion_usecases.dart';

/// Restore Promotions from a supplier XLSX file.
class RestorePromotionsPanel extends StatefulWidget {
  const RestorePromotionsPanel({super.key, required this.onDone, required this.onCancel});

  /// Called after promotions were added.
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  State<RestorePromotionsPanel> createState() => _RestorePromotionsPanelState();
}

class _RestorePromotionsPanelState extends State<RestorePromotionsPanel> {
  String? _fileName;
  Uint8List? _bytes;
  bool _working = false;

  Future<void> _pick() async {
    final files = await FilePicker.pickFiles(dialogTitle: 'Select XLSX file', type: FileType.custom, allowedExtensions: ['xlsx']);
    final file = files.firstOrNull;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _fileName = file.name;
        _bytes = bytes;
      });
    }
  }

  Future<void> _restore() async {
    setState(() => _working = true);
    final result = await getIt<RestorePromotions>()(_bytes!);
    if (!mounted) return;
    setState(() => _working = false);
    switch (result) {
      case Ok(value: final s):
        final parts = [
          '${s.added} promotions added',
          if (s.skipped > 0) '${s.skipped} skipped',
          if (s.unknownProducts > 0) '${s.unknownProducts} unknown barcodes',
        ];
        showToast(context, parts.join(' · '), error: s.added == 0);
        if (s.added > 0) widget.onDone();
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Restore Promotions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 6),
                Text(
                  'Offer in column F (e.g. "3 FOR Rs 600"), barcode in column I, dates in D4 (dd/MM/yyyy - dd/MM/yyyy).',
                  style: TextStyle(color: c.muted),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'XLSX File',
                  child: Material(
                    color: c.inputFill,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.line)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _working ? null : _pick,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                        child: Column(
                          children: [
                            Icon(Icons.description_outlined, size: 34, color: c.muted),
                            const SizedBox(height: 8),
                            Text(
                              _fileName ?? 'Click here to select XLSX file',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w700, color: _fileName == null ? c.muted : c.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: PosButton(label: 'Cancel', height: 52, style: PosButtonStyle.secondary, onPressed: _working ? null : widget.onCancel)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PosButton(label: 'Restore', height: 52, style: PosButtonStyle.primary, onPressed: _bytes == null || _working ? null : _restore),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
