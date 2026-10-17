import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/data_import.dart';
import '../../domain/usecases/backup_usecases.dart';
import '../../domain/usecases/import_data.dart';

/// SetBackup.dc.html: back up the local database, or restore a backup.
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  String? _directory;
  String? _savedTo;
  String? _restoreFile;
  bool _fromCsv = false;
  ImportTable? _importTable;
  Uint8List? _importBytes;
  String? _importName;
  bool _working = false;

  Future<void> _pickDirectory() async {
    final dir = await FilePicker.getDirectoryPath(dialogTitle: 'Select backup destination');
    if (dir != null && mounted) {
      setState(() {
        _directory = dir;
        _savedTo = null;
      });
    }
  }

  Future<void> _pickBackup() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Select backup file', type: FileType.custom, allowedExtensions: ['db', 'sqlite', 'sqlite3']);
    if (file?.path case final path? when mounted) setState(() => _restoreFile = path);
  }

  Future<void> _backup() async {
    setState(() => _working = true);
    final result = await getIt<BackupDatabase>()(_directory);
    if (!mounted) return;
    setState(() => _working = false);
    switch (result) {
      case Ok(:final value):
        setState(() => _savedTo = value);
        showToast(context, 'Database backup completed successfully');
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _restore() async {
    final ok = await confirm(
      context,
      title: 'Restore this backup?',
      message: 'Everything on this till since the backup was taken will be replaced. The current database is kept as a copy.',
      confirmLabel: 'Restore',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _working = true);
    final result = await getIt<RestoreDatabase>()(_restoreFile);
    if (!mounted) return;
    setState(() => _working = false);
    switch (result) {
      case Ok():
        final close = await confirm(
          context,
          title: 'Restart Tillora',
          message: 'The backup is ready. It is restored the next time Tillora starts. Close Tillora now and open it again.',
          confirmLabel: 'Close Tillora',
          cancelLabel: 'Later',
        );
        if (close) exit(0);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'Backup & Restore',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 900;
          final backup = Panel(child: _backupSection(context));
          final restore = Panel(child: _restoreSection(context));
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 26 : 12),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: backup),
                      const SizedBox(width: 20),
                      Expanded(child: restore),
                    ],
                  )
                : Column(children: [backup, const SizedBox(height: 16), restore]),
          );
        },
      ),
    );
  }

  Widget _heading(BuildContext context, IconData icon, Color ink, Color fill, String text) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: ink),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: context.colors.ink),
        ),
      ),
    ],
  );

  Widget _picker(BuildContext context, {required String? value, required String placeholder, required IconData icon, required VoidCallback onTap}) {
    final c = context.colors;
    return Material(
      color: c.inputFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: value == null ? c.line : c.primary, width: value == null ? 1 : 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _working ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: c.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? placeholder,
                  style: TextStyle(fontWeight: FontWeight.w700, color: value == null ? c.muted : c.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backupSection(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, Icons.download_rounded, context.colors.noteInk, context.colors.noteFill, 'Backup local database'),
        const SizedBox(height: 18),
        Text(
          'Select backup destination',
          style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary),
        ),
        const SizedBox(height: 8),
        _picker(context, value: _directory, placeholder: 'Please select a directory to backup', icon: Icons.folder_open_outlined, onTap: _pickDirectory),
        if (_savedTo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.colors.noteFill, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'Database backup completed successfully\n$_savedTo',
              style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.noteInk),
            ),
          ),
        ],
        const SizedBox(height: 18),
        PosButton(label: 'Backup', height: 54, style: PosButtonStyle.primary, onPressed: _directory == null || _working ? null : _backup),
      ],
    );
  }

  Widget _restoreSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, Icons.restore_rounded, context.colors.holdInk, context.colors.holdFill, 'Restore local database'),
        const SizedBox(height: 14),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, label: Text('Backup file')),
            ButtonSegment(value: true, label: Text('CSV / Excel')),
          ],
          selected: {_fromCsv},
          onSelectionChanged: _working ? null : (s) => setState(() => _fromCsv = s.first),
        ),
        const SizedBox(height: 16),
        if (_fromCsv) ..._csvImport(context) else ..._backupRestore(context),
      ],
    );
  }

  List<Widget> _csvImport(BuildContext context) {
    final c = context.colors;
    return [
      LabeledField(
        label: 'Select Table',
        child: DropdownButtonFormField<ImportTable>(
          initialValue: _importTable,
          isExpanded: true,
          hint: const Text('Please Select Table'),
          items: [for (final t in ImportTable.values) DropdownMenuItem(value: t, child: Text(t.label))],
          onChanged: _working ? null : (t) => setState(() => _importTable = t),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'Excel/CSV File',
        style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary),
      ),
      const SizedBox(height: 8),
      _picker(context, value: _importName, placeholder: 'Click here to select Excel/CSV file', icon: Icons.table_chart_outlined, onTap: _pickImport),
      const SizedBox(height: 8),
      Text(
        'Columns are matched by heading (e.g. Barcode, Description, Price). Rows already on the till are skipped. A file from Extract Product Data imports as it is.',
        style: TextStyle(color: c.muted),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: PosButton(
              label: 'Cancel',
              height: 54,
              style: PosButtonStyle.secondary,
              onPressed: _importBytes == null || _working
                  ? null
                  : () => setState(() {
                      _importBytes = null;
                      _importName = null;
                    }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PosButton(label: 'Upload file', height: 54, style: PosButtonStyle.primary, onPressed: _importBytes == null || _working ? null : _import),
          ),
        ],
      ),
    ];
  }

  Future<void> _pickImport() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Select Excel/CSV file', type: FileType.custom, allowedExtensions: ImportData.extensions);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _importBytes = bytes;
        _importName = file.name;
      });
    }
  }

  Future<void> _import() async {
    setState(() => _working = true);
    final ext = (_importName ?? '').split('.').last;
    final result = await getIt<ImportData>()(_importTable, _importBytes, ext);
    if (!mounted) return;
    setState(() => _working = false);
    switch (result) {
      case Ok(value: final s):
        final lines = ['${s.added} added', if (s.existing > 0) '${s.existing} already on the till', if (s.invalid > 0) '${s.invalid} skipped'];
        await confirm(
          context,
          title: '${_importTable!.label} import',
          message: [lines.join(' · '), ...s.problems].join('\n'),
          confirmLabel: 'OK',
          cancelLabel: 'Close',
        );
        if (mounted) {
          setState(() {
            _importBytes = null;
            _importName = null;
          });
        }
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  List<Widget> _backupRestore(BuildContext context) {
    final c = context.colors;
    return [
      Text(
        'Backup File',
        style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary),
      ),
      const SizedBox(height: 8),
      _picker(context, value: _restoreFile, placeholder: 'Click here to select backup file', icon: Icons.insert_drive_file_outlined, onTap: _pickBackup),
      const SizedBox(height: 8),
      Text('Tillora closes to finish the restore. The current database is kept as a copy next to it.', style: TextStyle(color: c.muted)),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: PosButton(
              label: 'Cancel',
              height: 54,
              style: PosButtonStyle.secondary,
              onPressed: _restoreFile == null || _working ? null : () => setState(() => _restoreFile = null),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PosButton(label: 'Restore', height: 54, style: PosButtonStyle.danger, onPressed: _restoreFile == null || _working ? null : _restore),
          ),
        ],
      ),
    ];
  }
}
