import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/usecases/extract_products.dart';

/// SetExtract.dc.html: save the products table of a database file as CSV.
class ExtractProductsScreen extends StatefulWidget {
  const ExtractProductsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ExtractProductsScreen> createState() => _ExtractProductsScreenState();
}

class _ExtractProductsScreenState extends State<ExtractProductsScreen> {
  String? _file;
  String? _fileName;
  String? _savedTo;
  bool _working = false;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Select SQLite database file', type: FileType.custom, allowedExtensions: ['db', 'sqlite', 'sqlite3']);
    if (file?.path case final path? when mounted) {
      setState(() {
        _file = path;
        _fileName = file!.name;
        _savedTo = null;
      });
    }
  }

  Future<void> _extract() async {
    setState(() => _working = true);
    final result = await getIt<ExtractProducts>()(_file);
    if (!mounted) return;
    switch (result) {
      case Ok(value: (:final products, :final bytes)):
        final uri = await FilePicker.saveFile(
          dialogTitle: 'Save products as CSV',
          fileName: 'products-${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
          bytes: bytes,
          mimeType: 'text/csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
        if (!mounted) return;
        setState(() {
          _working = false;
          _savedTo = uri == null ? null : (uri.scheme == 'file' ? uri.toFilePath() : '$uri');
        });
        if (uri != null) showToast(context, '$products products saved');
      case Err(:final failure):
        setState(() => _working = false);
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'Extract Product Data',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Pick a SQLite database file and save its product table as a CSV file.', style: TextStyle(fontSize: 15, color: c.inkSecondary)),
                  const SizedBox(height: 16),
                  Text('SQLite Database File', style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
                  const SizedBox(height: 8),
                  Material(
                    color: c.inputFill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: _file == null ? c.line : c.primary, width: _file == null ? 1 : 2),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _working ? null : _pick,
                      child: SizedBox(
                        height: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storage_rounded, size: 34, color: c.muted),
                            const SizedBox(height: 8),
                            Text(
                              _fileName ?? 'Click here to select SQLite database file',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _file == null ? c.muted : c.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_savedTo != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(12)),
                      child: Text('CSV file saved at $_savedTo', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.successInk)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  PosButton(label: 'Extract', height: 56, fontSize: 16, style: PosButtonStyle.primary, onPressed: _file == null || _working ? null : _extract),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
