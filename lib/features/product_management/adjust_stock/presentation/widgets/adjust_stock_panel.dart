import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/adjust_stock_repository.dart';
import '../../domain/usecases/adjust_stock_usecases.dart';

/// Adjust Stock: find a product, then add or remove stock with a reason.
class AdjustStockPanel extends StatefulWidget {
  const AdjustStockPanel({super.key});

  @override
  State<AdjustStockPanel> createState() => _AdjustStockPanelState();
}

class _AdjustStockPanelState extends State<AdjustStockPanel> {
  final _query = TextEditingController();
  final _quantity = TextEditingController();
  StockItem? _item;
  StockReason _reason = StockReason.stockIn;
  bool _saving = false;

  int get _qty => int.tryParse(_quantity.text.trim()) ?? 0;

  @override
  void dispose() {
    _query.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final result = await getIt<FindStockItem>()(_query.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _item = value);
      case Err(:final failure):
        setState(() => _item = null);
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _adjust() async {
    setState(() => _saving = true);
    final result = await getIt<AdjustStock>()(_item!, reason: _reason, quantity: _qty);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        showToast(context, 'Stock for ${_item!.description} is now $value');
        _quantity.clear();
        _find();
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final item = _item;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _find(),
                decoration: const InputDecoration(hintText: 'Search Barcode', prefixIcon: Icon(Icons.qr_code_scanner_rounded)),
              ),
            ),
            const SizedBox(width: 10),
            PosButton(label: 'Find', height: 56, style: PosButtonStyle.primary, onPressed: _find),
          ],
        ),
        const SizedBox(height: 18),
        if (item == null)
          Text('Please scan barcode and tap Find to load data', style: TextStyle(color: c.muted))
        else ...[
          FieldGrid(
            children: [
              LabeledField(label: 'Description', child: ReadOnlyField(item.description)),
              LabeledField(label: 'Current Stock', child: ReadOnlyField('${item.stock}')),
              LabeledField(
                label: 'Reason',
                child: SegmentedButton<StockReason>(
                  segments: [for (final r in StockReason.values) ButtonSegment(value: r, label: Text(r.label))],
                  selected: {_reason},
                  onSelectionChanged: (s) => setState(() => _reason = s.first),
                ),
              ),
              LabeledField(
                label: 'Quantity',
                child: TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: '0'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(color: c.selection, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Text('New Stock', style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
                const Spacer(),
                Text('${AdjustStock.newStock(item, _reason, _qty)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PosButton(
            label: 'Adjust Stock',
            height: 54,
            fontSize: 16,
            style: PosButtonStyle.primary,
            onPressed: _saving || _qty <= 0 ? null : _adjust,
          ),
        ],
      ],
    );
  }
}
