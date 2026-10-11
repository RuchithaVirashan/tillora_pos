import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/price_change_repository.dart';
import '../../domain/usecases/price_change_usecases.dart';

/// Price Change: find a product, set a new price, or record its expiry.
class PriceChangePanel extends StatefulWidget {
  const PriceChangePanel({super.key});

  @override
  State<PriceChangePanel> createState() => _PriceChangePanelState();
}

class _PriceChangePanelState extends State<PriceChangePanel> {
  final _query = TextEditingController();
  final _newPrice = TextEditingController();
  PricedProduct? _product;

  @override
  void dispose() {
    _query.dispose();
    _newPrice.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final result = await getIt<FindPricedProduct>()(_query.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _product = value);
      case Err(:final failure):
        setState(() => _product = null);
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _done(Result<void> result, String message) async {
    if (!mounted) return;
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, message);
    _query.text = _product!.barcode;
    await _find();
  }

  Future<void> _update() async {
    final cents = Money.toCents(double.tryParse(_newPrice.text.trim()) ?? 0);
    final result = await getIt<ChangePrice>()(_product!, cents);
    if (result.isSuccess) _newPrice.clear();
    await _done(result, 'Price updated successfully');
  }

  Future<void> _confirmExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      initialDate: _product!.expiryDate ?? now.add(const Duration(days: 7)),
      helpText: 'Expiry date',
    );
    if (date == null) return;
    await _done(await getIt<SetProductExpiry>()(_product!, date), 'Expiry date saved');
  }

  Future<void> _markExpired() async {
    final ok = await confirm(
      context,
      title: 'Mark as Expired',
      message: '${_product!.description} will warn at the till from today.',
      confirmLabel: 'Mark as Expired',
      destructive: true,
    );
    if (!ok) return;
    await _done(await getIt<SetProductExpiry>()(_product!, DateTime.now()), 'Marked as expired');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = _product;
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
        if (p == null)
          Text('Find a product to change its price. After updating you can print a label once the label printer is set up.',
              style: TextStyle(color: c.muted))
        else ...[
          FieldGrid(
            children: [
              LabeledField(label: 'Item Barcode', child: ReadOnlyField(p.barcode)),
              LabeledField(label: 'Item Description', child: ReadOnlyField(p.description)),
              LabeledField(label: 'Current Price', child: ReadOnlyField(Money.lkr(Money.fromCents(p.priceCents)), emphasis: true)),
              LabeledField(
                label: 'New Price',
                child: TextField(
                  controller: _newPrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _update(),
                  decoration: const InputDecoration(prefixText: 'Rs ', hintText: '0.00'),
                ),
              ),
            ],
          ),
          if (p.expiryDate != null) ...[
            const SizedBox(height: 10),
            Text('Expiry ${DateFormat('d MMM y').format(p.expiryDate!)}', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: PosButton(label: 'Confirm Expiration', height: 54, style: PosButtonStyle.secondary, onPressed: _confirmExpiry)),
              const SizedBox(width: 10),
              Expanded(child: PosButton(label: 'Mark as Expired', height: 54, style: PosButtonStyle.voidTint, onPressed: _markExpired)),
              const SizedBox(width: 10),
              Expanded(child: PosButton(label: 'Update', height: 54, fontSize: 16, style: PosButtonStyle.success, onPressed: _update)),
            ],
          ),
        ],
      ],
    );
  }
}
