import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/amount_display.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/numeric_keypad.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/sellable_item.dart';
import '../../domain/usecases/weigh_item.dart';

/// Pick a product sold by weight and enter grams or price.
/// Pops the weighed [SellableItem].
class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _query = TextEditingController();
  List<SellableItem>? _products;
  SellableItem? _selected;
  String _entry = '';

  /// Enter grams (default) or the price to charge.
  bool _byPrice = false;

  int get _grams {
    final product = _selected;
    if (product == null) return 0;
    if (!_byPrice) return int.tryParse(_entry) ?? 0;
    return WeighItem.gramsFor(product, Money.toCents(double.tryParse(_entry) ?? 0));
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final result = await getIt<GetWeighedProducts>()(_query.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _products = value;
          if (value.length == 1) _selected = value.first;
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _add() {
    switch (const WeighItem()(_selected!, grams: _grams)) {
      case Ok(:final value):
        context.pop(value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final left = _left(context);
    final right = _right();
    return PosDialog(
      title: 'Weight Item',
      icon: Icons.scale_outlined,
      iconColor: context.colors.primary,
      iconFill: context.colors.selection,
      width: 960,
      child: SingleChildScrollView(
        child: phone
            ? Column(children: [left, const SizedBox(height: 20), right])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 24), SizedBox(width: 340, child: right)]),
      ),
    );
  }

  Widget _left(BuildContext context) {
    final c = context.colors;
    final products = _products;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(hintText: 'Barcode or description'),
              ),
            ),
            const SizedBox(width: 10),
            PosButton(label: 'Search', height: 56, style: PosButtonStyle.primary, onPressed: _search),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 300,
          child: products == null
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
              ? Center(
                  child: Text('No weighed products found.\nAdd them in Product Management › Weight Items.',
                      textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
                )
              : ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    final on = p == _selected;
                    return Material(
                      color: on ? c.selection : c.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: on ? c.primary : c.line, width: on ? 2 : 1),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onTap: () => setState(() => _selected = p),
                        title: Text(p.description, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                        subtitle: Text(p.departmentName, style: TextStyle(color: c.muted)),
                        trailing: Text('${Money.lkr(Money.fromCents(p.priceCents))} / kg',
                            style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _right() {
    final product = _selected;
    final grams = _grams;
    final cents = product == null ? 0 : (product.priceCents * grams / 1000).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [ButtonSegment(value: false, label: Text('Grams')), ButtonSegment(value: true, label: Text('Price'))],
          selected: {_byPrice},
          onSelectionChanged: (s) => setState(() {
            _byPrice = s.first;
            _entry = '';
          }),
        ),
        const SizedBox(height: 12),
        AmountDisplay(
          label: product == null ? 'Select a product' : '$grams g · ${Money.lkr(Money.fromCents(cents))}',
          text: _byPrice ? Money.lkr(double.tryParse(_entry) ?? 0) : '${_entry.isEmpty ? 0 : _entry} g',
        ),
        const SizedBox(height: 12),
        NumericKeypad(
          withDot: _byPrice,
          keyHeight: 56,
          onKey: (k) => setState(() => _entry = _byPrice ? applyAmountKey(_entry, k) : _gramsKey(k)),
        ),
        const SizedBox(height: 12),
        PosButton(
          label: 'Add to sale',
          height: 58,
          fontSize: 16,
          style: PosButtonStyle.success,
          onPressed: product != null && grams > 0 ? _add : null,
        ),
      ],
    );
  }

  String _gramsKey(String k) {
    if (k == PadKey.delete) return _entry.isEmpty ? _entry : _entry.substring(0, _entry.length - 1);
    final next = _entry + k;
    return next.length > 6 ? _entry : next;
  }
}
