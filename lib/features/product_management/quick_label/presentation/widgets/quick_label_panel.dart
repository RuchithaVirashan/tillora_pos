import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../back_office/label_printer/domain/entities/label_product.dart';
import '../../../../back_office/label_printer/domain/usecases/label_usecases.dart';

/// Quick Label: find one product and print its shelf label on the QL label
/// printer or the till receipt printer.
class QuickLabelPanel extends StatefulWidget {
  const QuickLabelPanel({super.key});

  @override
  State<QuickLabelPanel> createState() => _QuickLabelPanelState();
}

class _QuickLabelPanelState extends State<QuickLabelPanel> {
  final _query = TextEditingController();
  final _count = TextEditingController(text: '1');
  LabelProduct? _product;
  LabelFormat _format = LabelFormat.roll;
  bool _printing = false;

  static const _formats = {LabelFormat.roll: 'QL Label', LabelFormat.receipt: 'Receipt'};

  int get _labels => int.tryParse(_count.text.trim()) ?? 0;

  @override
  void dispose() {
    _query.dispose();
    _count.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final result = await getIt<FindLabelProduct>()(_query.text, LabelType.barcode);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _product = value);
      case Err(:final failure):
        setState(() => _product = null);
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _print() async {
    setState(() => _printing = true);
    final result = await getIt<PrintLabels>()([(product: _product!, count: _labels)], LabelType.barcode, _format);
    if (!mounted) return;
    setState(() => _printing = false);
    switch (result) {
      case Ok():
        showToast(context, '$_labels ${_labels == 1 ? 'label' : 'labels'} sent to the printer');
      case Err(:final failure):
        showToast(context, 'Could not print: ${failure.message}', error: true);
    }
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
          Text('Scan a barcode to print its shelf label', style: TextStyle(color: c.muted))
        else ...[
          FieldGrid(
            children: [
              LabeledField(label: 'Description', child: ReadOnlyField(p.description)),
              LabeledField(label: 'Price', child: ReadOnlyField(Money.lkr(Money.fromCents(p.priceCents)), emphasis: true)),
              LabeledField(
                label: 'Label Type',
                child: SegmentedButton<LabelFormat>(
                  showSelectedIcon: false,
                  segments: [for (final MapEntry(:key, :value) in _formats.entries) ButtonSegment(value: key, label: Text(value))],
                  selected: {_format},
                  onSelectionChanged: (s) => setState(() => _format = s.first),
                ),
              ),
              LabeledField(
                label: 'Labels',
                child: TextField(
                  controller: _count,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _format == LabelFormat.roll ? 'Prints on the label printer set in System Configuration.' : 'Prints on the till receipt printer.',
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 16),
          PosButton(
            label: 'Print Label',
            icon: Icons.print_outlined,
            height: 54,
            fontSize: 16,
            style: PosButtonStyle.primary,
            onPressed: _printing || _labels <= 0 ? null : _print,
          ),
        ],
      ],
    );
  }
}
