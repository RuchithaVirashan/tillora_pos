import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/maintenance_tool.dart';
import '../../domain/usecases/maintenance_usecases.dart';

/// SetDatabase.dc.html: checks and repairs for the local database. Each
/// tool shows what it found before anything changes.
class DatabaseMaintenanceScreen extends StatefulWidget {
  const DatabaseMaintenanceScreen({super.key, required this.onBack, required this.onOpenBackup});

  final VoidCallback onBack;
  final VoidCallback onOpenBackup;

  @override
  State<DatabaseMaintenanceScreen> createState() => _DatabaseMaintenanceScreenState();
}

class _DatabaseMaintenanceScreenState extends State<DatabaseMaintenanceScreen> {
  MaintenanceTool? _running;

  Future<void> _open(MaintenanceTool tool) async {
    setState(() => _running = tool);
    final result = await getIt<InspectDatabase>()(tool);
    if (!mounted) return;
    setState(() => _running = null);
    switch (result) {
      case Ok(value: final finding):
        final fix = await showDialog<bool>(context: context, builder: (_) => _FindingDialog(tool: tool, finding: finding));
        if (fix == true && mounted) await _fix(tool, finding);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _fix(MaintenanceTool tool, MaintenanceFinding finding) async {
    setState(() => _running = tool);
    final result = await getIt<RepairDatabase>()(tool, finding);
    if (!mounted) return;
    setState(() => _running = null);
    switch (result) {
      case Ok(:final value):
        showToast(context, '${tool.label}: $value ${value == 1 ? 'row' : 'rows'} fixed');
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'Update Local Database',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warningLine)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warningInk),
                const SizedBox(width: 10),
                const Expanded(child: Text('Take a backup before running any fix.', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.warningInk))),
                TextButton(onPressed: widget.onOpenBackup, child: const Text('Backup & Restore')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final tool in MaintenanceTool.values)
                SizedBox(
                  width: 340,
                  child: Material(
                    color: c.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _running == null ? () => _open(tool) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: tool.fixes ? AppColors.warningTint : AppColors.successTint,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: _running == tool
                                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(
                                      tool.fixes ? Icons.build_outlined : Icons.health_and_safety_outlined,
                                      color: tool.fixes ? AppColors.warningInk : AppColors.successInk,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tool.label, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                                  Text(tool.description, style: TextStyle(color: c.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What a check found, with Fix when there is something to repair.
class _FindingDialog extends StatelessWidget {
  const _FindingDialog({required this.tool, required this.finding});

  final MaintenanceTool tool;
  final MaintenanceFinding finding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final clean = finding.count == 0;
    final canFix = tool.fixes && !clean;
    return PosDialog(
      title: tool.label,
      subtitle: tool.description,
      icon: clean ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
      iconColor: clean ? AppColors.success : AppColors.warningInk,
      iconFill: clean ? AppColors.successTint : AppColors.warningTint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(finding.detail, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: PosButton(label: canFix ? 'Cancel' : 'Close', height: 52, style: PosButtonStyle.secondary, onPressed: () => Navigator.of(context).pop(false))),
              if (canFix) ...[
                const SizedBox(width: 10),
                Expanded(child: PosButton(label: 'Fix ${finding.count}', height: 52, style: PosButtonStyle.primary, onPressed: () => Navigator.of(context).pop(true))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
