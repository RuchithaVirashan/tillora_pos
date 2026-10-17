import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/stock_entry.dart';
import '../../domain/usecases/stock_manager_usecases.dart';

/// Adjust Stock: pick a reason, add or remove a quantity.
/// Pops with the new stock level once saved.
class AdjustStockDialog extends StatefulWidget {
  const AdjustStockDialog({super.key, required this.entry});

  final StockEntry entry;

  static Future<int?> show(BuildContext context, StockEntry entry) =>
      showDialog<int>(context: context, builder: (_) => AdjustStockDialog(entry: entry));

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _qty = TextEditingController();
  StockAdjustReason _reason = StockAdjustReason.delivery;
  bool _adding = true;
  bool _saving = false;

  int get _delta => (int.tryParse(_qty.text.trim()) ?? 0) * (_adding ? 1 : -1);

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  void _pickReason(StockAdjustReason r) => setState(() {
    _reason = r;
    if (r.sign != 0) _adding = r.sign > 0;
  });

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await getIt<AdjustProductStock>()(widget.entry, reason: _reason, delta: _delta);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = widget.entry;
    return PosDialog(
      title: 'Adjust Stock',
      subtitle: e.description,
      icon: Icons.tune_rounded,
      iconColor: const Color(0xFF0B7A55),
      iconFill: context.colors.noteFill,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: 'Reason',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in StockAdjustReason.values)
                  ChoiceChip(label: Text(r.label), selected: _reason == r, onSelected: (_) => _pickReason(r)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: LabeledField(label: 'Current Stock', child: ReadOnlyField('${e.stock}'))),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: 'Quantity',
                  child: TextField(
                    controller: _qty,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixIcon: IconButton(
                        tooltip: _adding ? 'Adding' : 'Removing',
                        onPressed: _reason.sign == 0 ? () => setState(() => _adding = !_adding) : null,
                        icon: Text(_adding ? '+' : '−', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _adding ? AppColors.success : AppColors.danger)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(color: c.selection, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Text('New Stock', style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
                const Spacer(),
                Text('${e.stock + _delta}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.primary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: PosButton(label: 'Cancel', height: 54, style: PosButtonStyle.secondary, onPressed: () => Navigator.of(context).pop())),
              const SizedBox(width: 10),
              Expanded(
                child: PosButton(label: 'Save', height: 54, style: PosButtonStyle.primary, onPressed: _saving || _delta == 0 ? null : _save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
