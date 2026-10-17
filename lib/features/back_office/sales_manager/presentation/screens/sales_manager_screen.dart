import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/sale_line.dart';
import '../../domain/usecases/sales_manager_usecases.dart';

/// BOSalesManager.dc.html: Adjust Misfired. Lines rung up by mistake in
/// closed shifts are taken off their sales, or their quantity lowered.
class SalesManagerScreen extends StatefulWidget {
  const SalesManagerScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SalesManagerScreen> createState() => _SalesManagerScreenState();
}

class _SalesManagerScreenState extends State<SalesManagerScreen> {
  final _allowed = getIt<SessionHolder>().value?.access.can('salesManagerAccess') ?? false;
  final _shiftFormat = DateFormat('d MMM HH:mm');
  late DateTime _from = _today;
  late DateTime _to = _today;
  List<ShiftOption> _shifts = const [];
  int? _logId;

  /// Null shows every payment type.
  PayKind? _kind;
  List<SaleLine>? _lines;
  final _picked = <int>{};
  bool _working = false;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The end date is inclusive.
  DateTime get _toExclusive => _to.add(const Duration(days: 1));

  List<SaleLine> get _shown => [for (final l in _lines ?? const <SaleLine>[]) if (_kind == null || l.kind == _kind) l];

  List<SaleLine> get _selected => [for (final l in _lines ?? const <SaleLine>[]) if (_picked.contains(l.itemId)) l];

  @override
  void initState() {
    super.initState();
    if (_allowed) _reload();
  }

  Future<void> _reload() async {
    final shifts = await getIt<GetClosedShifts>()(_from, _toExclusive);
    if (!mounted) return;
    setState(() {
      _shifts = switch (shifts) {
        Ok(:final value) => value,
        Err() => const [],
      };
      if (!_shifts.any((s) => s.logId == _logId)) _logId = null;
    });
    await _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetSaleLines>()(_from, _toExclusive, logId: _logId);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _lines = value;
          _picked.retainAll(value.map((l) => l.itemId));
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _delete() async {
    final lines = _selected;
    final ok = await confirm(
      context,
      title: 'Delete items?',
      message: 'Are you sure you want to delete ${lines.length == 1 ? 'this item' : 'these ${lines.length} items'}? '
          '${Money.lkr(Money.fromCents(lines.fold(0, (s, l) => s + l.amountCents)))} comes off the sales and the items go back to stock.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _working = true);
    final result = await getIt<RemoveSaleLines>()(lines);
    if (!mounted) return;
    setState(() => _working = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${lines.length} ${lines.length == 1 ? 'item' : 'items'} deleted');
    _picked.clear();
    _load();
  }

  Future<void> _alter() async {
    final line = _selected.single;
    final quantity = await showDialog<int>(context: context, builder: (_) => _AlterDialog(line: line));
    if (quantity == null || !mounted) return;
    setState(() => _working = true);
    final result = await getIt<AlterSaleLine>()(line, quantity);
    if (!mounted) return;
    setState(() => _working = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${line.description} changed to $quantity');
    _picked.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · MANAGE SALES',
      title: 'Adjust Misfired',
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: !_allowed
          ? const NoAccess(what: 'Sales Manager')
          : LayoutBuilder(
              builder: (context, box) {
                final narrow = box.maxWidth < 760;
                // Phones scroll the whole page: the filters alone fill the height.
                if (box.maxWidth < 600) {
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _filters(context, narrow: true),
                      const SizedBox(height: 12),
                      SizedBox(height: 460, child: _table(context, narrow: true)),
                      const SizedBox(height: 12),
                      _footer(context),
                    ],
                  );
                }
                return Padding(
                  padding: EdgeInsets.all(narrow ? 12 : 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _filters(context, narrow: narrow),
                      const SizedBox(height: 14),
                      Expanded(child: _table(context, narrow: narrow)),
                      const SizedBox(height: 12),
                      _footer(context),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _filters(BuildContext context, {required bool narrow}) {
    final c = context.colors;
    final period = (_lines ?? const <SaleLine>[]).fold(0, (s, l) => s + l.amountCents);
    final field = narrow ? double.infinity : 190.0;
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: field,
            child: LabeledField(
              label: 'Start Date',
              child: DateField(
                value: _from,
                lastDate: _today,
                onChanged: (d) {
                  setState(() {
                    _from = d;
                    if (_to.isBefore(d)) _to = d;
                  });
                  _reload();
                },
              ),
            ),
          ),
          SizedBox(
            width: field,
            child: LabeledField(
              label: 'End Date',
              child: DateField(
                value: _to,
                lastDate: _today,
                onChanged: (d) {
                  setState(() {
                    _to = d;
                    if (_from.isAfter(d)) _from = d;
                  });
                  _reload();
                },
              ),
            ),
          ),
          SizedBox(
            width: narrow ? double.infinity : 280,
            child: LabeledField(
              label: 'Shift',
              child: DropdownButtonFormField<int?>(
                key: ValueKey(_shifts.length),
                initialValue: _logId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All closed shifts')),
                  for (final s in _shifts)
                    DropdownMenuItem(
                      value: s.logId,
                      child: Text(
                        '#${s.logId} · ${s.userName} · ${_shiftFormat.format(s.started)}${s.ended == null ? '' : ' – ${_shiftFormat.format(s.ended!)}'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  setState(() => _logId = v);
                  _load();
                },
              ),
            ),
          ),
          LabeledField(
            label: 'Payment Type',
            child: SegmentedButton<PayKind?>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(value: null, label: Text('All')),
                for (final k in PayKind.values) ButtonSegment(value: k, label: Text(k.label)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Total for Selected Time Period:  ', style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
                  TextSpan(text: Money.lkr(Money.fromCents(period)), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final c = context.colors;
    final shown = _shown.fold(0, (s, l) => s + l.amountCents);
    final selected = _selected;
    final label = TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary);
    final value = TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.ink);
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text.rich(TextSpan(children: [TextSpan(text: 'Sale Total: ', style: label), TextSpan(text: Money.lkr(Money.fromCents(shown)), style: value)])),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Selected Total: ', style: label),
                TextSpan(text: Money.lkr(Money.fromCents(selected.fold(0, (s, l) => s + l.amountCents))), style: value.copyWith(color: c.primary)),
              ],
            ),
          ),
          PosButton(label: 'Delete', height: 48, style: PosButtonStyle.danger, onPressed: selected.isEmpty || _working ? null : _delete),
          PosButton(
            label: 'Alter',
            height: 48,
            style: PosButtonStyle.secondary,
            onPressed: selected.length != 1 || selected.single.quantity < 2 || _working ? null : _alter,
          ),
        ],
      ),
    );
  }

  Widget _table(BuildContext context, {required bool narrow}) {
    final c = context.colors;
    final lines = _lines == null ? null : _shown;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    Widget right(Widget w) => Align(alignment: Alignment.centerRight, child: w);
    Widget cols(List<Widget> cells) => Row(
      children: [
        SizedBox(width: 44, child: cells[0]),
        if (!narrow) SizedBox(width: 80, child: cells[1]),
        Expanded(child: cells[2]),
        SizedBox(width: 50, child: right(cells[3])),
        if (!narrow) SizedBox(width: 120, child: right(cells[4])),
        SizedBox(width: 120, child: right(cells[5])),
        if (!narrow) ...[const SizedBox(width: 20), SizedBox(width: 150, child: cells[6])],
      ],
    );
    final allPicked = lines != null && lines.isNotEmpty && lines.every((l) => _picked.contains(l.itemId));
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: cols([
              Checkbox(
                value: allPicked,
                onChanged: lines == null || lines.isEmpty
                    ? null
                    : (v) => setState(() => v == true ? _picked.addAll(lines.map((l) => l.itemId)) : _picked.removeAll(lines.map((l) => l.itemId))),
              ),
              Text('ID', style: head),
              Text('DESCRIPTION', style: head),
              Text('QTY', style: head),
              Text('PRICE', style: head),
              Text('AMOUNT', style: head),
              Text('PAYMENT TYPE', style: head),
            ]),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: switch (lines) {
              null => const Center(child: CircularProgressIndicator()),
              [] => Center(child: Text('No sales in closed shifts for this period', style: TextStyle(color: c.muted))),
              _ => ListView.builder(
                itemCount: lines.length,
                itemExtent: 54,
                itemBuilder: (context, i) {
                  final l = lines[i];
                  final on = _picked.contains(l.itemId);
                  final body = TextStyle(fontSize: 15, color: c.inkSecondary);
                  void flip() => setState(() => on ? _picked.remove(l.itemId) : _picked.add(l.itemId));
                  return Material(
                    color: on ? c.selection : c.surface,
                    child: InkWell(
                      onTap: flip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: c.rowLine),
                            left: BorderSide(color: on ? AppColors.amber : Colors.transparent, width: 4),
                          ),
                        ),
                        child: cols([
                          Checkbox(value: on, onChanged: (_) => flip()),
                          Text('${l.transactionId}', style: body),
                          Text(
                            narrow ? '${l.description}\n#${l.transactionId} · ${l.payment}' : l.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: body.copyWith(fontWeight: FontWeight.w800, color: c.ink),
                          ),
                          Text('${l.quantity}', style: body),
                          Text(Money.lkr(Money.fromCents(l.priceCents)), style: body),
                          Text(Money.lkr(Money.fromCents(l.amountCents)), style: body.copyWith(color: c.ink)),
                          Text(l.payment, overflow: TextOverflow.ellipsis, style: body),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// Asks for the new, lower quantity of one line.
class _AlterDialog extends StatefulWidget {
  const _AlterDialog({required this.line});

  final SaleLine line;

  @override
  State<_AlterDialog> createState() => _AlterDialogState();
}

class _AlterDialogState extends State<_AlterDialog> {
  final _qty = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  int? get _value => int.tryParse(_qty.text.trim());

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = widget.line;
    final v = _value;
    final valid = v != null && v < l.quantity;
    return PosDialog(
      title: 'Alter Quantity',
      subtitle: '${l.description} · sale #${l.transactionId}',
      icon: Icons.edit_outlined,
      iconColor: c.primary,
      iconFill: c.selection,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: LabeledField(label: 'Sold', child: ReadOnlyField('${l.quantity}'))),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: 'Actual Quantity',
                  child: TextField(
                    controller: _qty,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (valid) Navigator.of(context).pop(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valid ? 'New amount ${Money.lkr(Money.fromCents(l.priceCents * v))}' : 'Enter a quantity below ${l.quantity}',
            style: TextStyle(fontWeight: FontWeight.w700, color: valid ? c.inkSecondary : c.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: PosButton(label: 'Cancel', height: 52, style: PosButtonStyle.secondary, onPressed: () => Navigator.of(context).pop())),
              const SizedBox(width: 10),
              Expanded(child: PosButton(label: 'Alter', height: 52, style: PosButtonStyle.primary, onPressed: valid ? () => Navigator.of(context).pop(v) : null)),
            ],
          ),
        ],
      ),
    );
  }
}
