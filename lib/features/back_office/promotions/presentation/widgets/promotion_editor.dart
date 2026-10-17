import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/usecases/promotion_usecases.dart';

/// Add Promotion: type, details and the products in each group.
/// [initial] null adds a new promotion.
class PromotionEditor extends StatefulWidget {
  const PromotionEditor({super.key, required this.initial, required this.onSave});

  final Promotion? initial;
  final Future<void> Function(Promotion) onSave;

  @override
  State<PromotionEditor> createState() => _PromotionEditorState();
}

class _PromotionEditorState extends State<PromotionEditor> {
  late final _p = widget.initial;
  late PromoType _type = _p?.type ?? PromoType.buyXGetY;
  late final _description = TextEditingController(text: _p?.description);
  late final _qty = TextEditingController(text: '${_p?.qty ?? 2}');
  late final _amount = TextEditingController(text: _p == null ? '' : Money.fromCents(_p.amountCents).toStringAsFixed(2));
  late DateTime _start = _p?.start ?? _today;
  late DateTime _end = _p?.end ?? _today.add(const Duration(days: 30));
  late final Map<int, List<PromoProduct>> _groups = {for (final e in (_p?.groups ?? const {}).entries) e.key: List.of(e.value)};
  final _scans = <int, TextEditingController>{};
  bool _saving = false;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get _groupCount => _type.groupNames.length;

  /// Bundles and meal deals set the quantity themselves.
  bool get _qtyFixed => _type != PromoType.buyXGetY;

  @override
  void dispose() {
    for (final c in [_description, _qty, _amount, ..._scans.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _scan(int group) => _scans.putIfAbsent(group, TextEditingController.new);

  void _pickType(PromoType t) => setState(() {
    _type = t;
    // Products in groups the new type does not have go back to group 1.
    final moved = [for (final g in _groups.keys.where((g) => g > t.groupNames.length)) ..._groups[g]!];
    _groups.removeWhere((g, _) => g > t.groupNames.length);
    if (moved.isNotEmpty) _groups.putIfAbsent(1, () => []).addAll(moved);
  });

  Future<void> _add(int group) async {
    final scan = _scan(group);
    final result = await getIt<FindPromoProduct>()(scan.text);
    if (!mounted) return;
    scan.clear();
    switch (result) {
      case Ok(value: final product):
        final inGroup = _groups.entries.where((e) => e.value.contains(product)).firstOrNull;
        if (inGroup != null) {
          showToast(context, '${product.description} is already in ${_type.groupNames[inGroup.key - 1]}', error: true);
          return;
        }
        setState(() => _groups.putIfAbsent(group, () => []).add(product));
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final products = _groups.values.fold(0, (n, g) => n + g.length);
    await widget.onSave(Promotion(
      id: _p?.id,
      description: _description.text,
      type: _type,
      start: _start,
      end: _end,
      qty: switch (_type) {
        PromoType.buyXGetY => int.tryParse(_qty.text.trim()) ?? 0,
        PromoType.bundle => products,
        PromoType.mealDeal => _groupCount,
      },
      amountCents: Money.toCents(double.tryParse(_amount.text.trim()) ?? 0),
      groups: {for (final e in _groups.entries) if (e.value.isNotEmpty) e.key: e.value},
    ));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final pad = wide ? 26.0 : 12.0;
        if (!wide) {
          return ListView(
            padding: EdgeInsets.all(pad),
            children: [Panel(child: _details(context)), const SizedBox(height: 16), ..._groupPanels(context)],
          );
        }
        return Padding(
          padding: EdgeInsets.all(pad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 460, child: Panel(child: SingleChildScrollView(child: _details(context)))),
              const SizedBox(width: 20),
              Expanded(child: ListView(children: _groupPanels(context))),
            ],
          ),
        );
      },
    );
  }

  Widget _details(BuildContext context) {
    final c = context.colors;
    final count = _groups.values.fold(0, (n, g) => n + g.length);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Promo Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (i, t) in PromoType.values.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: PosButton(
                  label: t.label,
                  height: 52,
                  fontSize: 13,
                  style: t == _type ? PosButtonStyle.outline : PosButtonStyle.secondary,
                  onPressed: () => _pickType(t),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        LabeledField(label: 'Description', child: TextField(controller: _description, decoration: const InputDecoration(hintText: 'Shown on the receipt'))),
        const SizedBox(height: 14),
        FieldGrid(
          children: [
            LabeledField(label: 'Start Date', child: DateField(value: _start, onChanged: (d) => setState(() => _start = d))),
            LabeledField(label: 'End Date', child: DateField(value: _end, onChanged: (d) => setState(() => _end = d))),
            LabeledField(
              label: 'QTY',
              child: _qtyFixed
                  ? ReadOnlyField('${_type == PromoType.bundle ? count : _groupCount}')
                  : TextField(controller: _qty, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
            LabeledField(
              label: 'Amount',
              child: TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                decoration: const InputDecoration(prefixText: 'Rs '),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_type.note, style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        PosButton(label: 'Save', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _saving ? null : _save),
      ],
    );
  }

  List<Widget> _groupPanels(BuildContext context) {
    final c = context.colors;
    return [
      for (var g = 1; g <= _groupCount; g++) ...[
        Panel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(_type.groupNames[g - 1], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink)),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _scan(g),
                      onSubmitted: (_) => _add(g),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Scan barcode to add',
                        prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                        suffixIcon: IconButton(tooltip: 'Add', onPressed: () => _add(g), icon: const Icon(Icons.add_rounded)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_groups[g]?.isEmpty ?? true)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No products yet', style: TextStyle(color: c.muted)))
              else
                for (final p in _groups[g]!)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rowLine))),
                    child: Row(
                      children: [
                        Expanded(child: Text(p.description, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink))),
                        Text(p.barcode, style: TextStyle(fontSize: 12, color: c.muted)),
                        const SizedBox(width: 12),
                        Text(Money.lkr(Money.fromCents(p.priceCents)), style: TextStyle(color: c.inkSecondary)),
                        IconButton(
                          tooltip: 'Remove ${p.description}',
                          onPressed: () => setState(() => _groups[g]!.remove(p)),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    ];
  }
}
