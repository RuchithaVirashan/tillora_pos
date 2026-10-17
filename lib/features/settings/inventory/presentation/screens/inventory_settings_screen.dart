import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/stock_reset_repository.dart';
import '../../domain/usecases/stock_reset_usecases.dart';

/// SetInventory.dc.html: reset all stock to zero before a full count.
class InventorySettingsScreen extends StatefulWidget {
  const InventorySettingsScreen({super.key, required this.onBack, required this.onOpenBackup});

  final VoidCallback onBack;
  final VoidCallback onOpenBackup;

  @override
  State<InventorySettingsScreen> createState() => _InventorySettingsScreenState();
}

class _InventorySettingsScreenState extends State<InventorySettingsScreen> {
  StockSummary? _summary;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetStockSummary>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _summary = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _reset() async {
    final s = _summary!;
    final ok = await confirm(
      context,
      title: 'Reset all stock?',
      message: 'Stock for ${s.products} products (${s.units} units) will be set to zero. Only a backup can bring it back.',
      confirmLabel: 'Stock reset',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _working = true);
    final result = await getIt<ResetStock>()(s);
    if (!mounted) return;
    setState(() => _working = false);
    switch (result) {
      case Ok(:final value):
        showToast(context, 'Stock reset for $value products');
        _load();
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = _summary;
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'Inventory',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.danger),
                  ),
                  const SizedBox(height: 14),
                  Text('Stock reset', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
                  const SizedBox(height: 8),
                  Text(
                    'Sets the stock of every product on this terminal back to zero. Use this before a full stock count. '
                    'Products and prices are not changed, and each reset shows in the Stock Adjustment report.',
                    style: TextStyle(fontSize: 15, color: c.inkSecondary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s == null ? 'Counting stock...' : '${s.products} products currently hold ${s.units} units.',
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warningLine)),
                    child: const Text('Take a backup first in Backup & Restore.', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.warningInk)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: PosButton(label: 'Backup first', height: 54, style: PosButtonStyle.secondary, onPressed: widget.onOpenBackup)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PosButton(
                          label: 'Stock reset',
                          height: 54,
                          style: PosButtonStyle.danger,
                          onPressed: s == null || s.products == 0 || _working ? null : _reset,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
