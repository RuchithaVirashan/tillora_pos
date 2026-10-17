import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/platform/report_output.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/report_export.dart';
import '../../../shift_report/domain/repositories/shift_report_repository.dart';
import '../../../shift_report/domain/usecases/shift_report_usecases.dart';
import '../../domain/entities/exception_record.dart';
import '../../domain/entities/exceptions_document.dart';
import '../../domain/usecases/get_exceptions.dart';

/// Exceptions.dc.html: voids, no sales, refunds and age refusals.
class ExceptionsScreen extends StatefulWidget {
  const ExceptionsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ExceptionsScreen> createState() => _ExceptionsScreenState();
}

class _ExceptionsScreenState extends State<ExceptionsScreen> {
  static const _flag = 'exceptionsAccess';

  final _allowed = getIt<SessionHolder>().value?.access.can(_flag) ?? false;
  final _date = DateFormat('d MMM · HH:mm');
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  ExceptionType _type = ExceptionType.voidLine;
  List<ShiftOption> _shifts = const [];
  int? _logId;
  List<ExceptionRecord>? _rows;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    final result = await getIt<FindShifts>()(from: _from, to: _to);
    if (result case Ok(:final value) when mounted) {
      setState(() {
        _shifts = value;
        if (!value.any((s) => s.logId == _logId)) _logId = null;
      });
    }
  }

  Future<void> _generate() async {
    final result = await getIt<GetExceptions>()(_type, from: _from, to: _to, logId: _logId);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _rows = value;
          _selected = 0;
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _export() {
    final rows = _rows;
    if (rows == null) return showToast(context, 'Choose filters and tap Generate first', error: true);
    final shift = _shifts.where((s) => s.logId == _logId).firstOrNull;
    printOrExportReport(
      context,
      exceptionsDocument(
        type: _type,
        from: _from,
        to: _to,
        records: rows,
        shift: shift == null ? null : '#${shift.logId} · ${shift.userName}',
      ),
      getIt<ReportOutput>(),
    );
  }

  String _rs(int cents) => '${cents < 0 ? '−' : ''}${Money.lkr(Money.fromCents(cents.abs()))}';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final rows = _rows;
    return ModuleScaffold(
      title: 'Exception Report',
      onBack: widget.onBack,
      backLabel: 'Back to Quick Report',
      body: !_allowed
          ? Padding(
              padding: const EdgeInsets.all(26),
              child: Panel(child: Text('You do not have access to exceptions.', style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700))),
            )
          : Padding(
              padding: EdgeInsets.all(phone ? 12 : 26),
              child: Column(
                children: [
                  Panel(child: _filters(context)),
                  const SizedBox(height: 18),
                  Expanded(
                    child: rows == null
                        ? Panel(child: Center(child: Text('Choose filters and tap Generate', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700))))
                        : phone
                        ? Column(children: [Expanded(child: _table(context, rows)), const SizedBox(height: 12), SizedBox(height: 220, child: _items(context, rows))])
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [Expanded(child: _table(context, rows)), const SizedBox(width: 18), SizedBox(width: 440, child: _items(context, rows))],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _filters(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldGrid(
          children: [
            LabeledField(
              label: 'Start Date',
              child: DateField(value: _from, lastDate: DateTime.now(), onChanged: (d) {
                setState(() => _from = d);
                _loadShifts();
              }),
            ),
            LabeledField(
              label: 'End Date',
              child: DateField(value: _to, lastDate: DateTime.now(), onChanged: (d) {
                setState(() => _to = d);
                _loadShifts();
              }),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Exceptions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in ExceptionType.values)
              ChoiceChip(
                label: Text(t.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                selected: t == _type,
                selectedColor: context.colors.voidFill,
                onSelected: (_) => setState(() => _type = t),
              ),
          ],
        ),
        const SizedBox(height: 14),
        FieldGrid(
          children: [
            LabeledField(
              label: 'Shift',
              child: DropdownButtonFormField<int?>(
                key: ValueKey('${_shifts.length}:$_logId'),
                initialValue: _logId,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All shifts')),
                  for (final s in _shifts) DropdownMenuItem<int?>(value: s.logId, child: Text('#${s.logId} · ${s.userName} · ${_date.format(s.startedAt)}')),
                ],
                onChanged: (v) => setState(() => _logId = v),
              ),
            ),
            LabeledField(
              label: ' ',
              child: Row(
                children: [
                  Expanded(child: PosButton(label: 'Generate', height: 52, style: PosButtonStyle.primary, onPressed: _generate)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PosButton(
                      label: 'Print Report',
                      height: 52,
                      style: PosButtonStyle.secondary,
                      onPressed: _export,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _table(BuildContext context, List<ExceptionRecord> rows) {
    final c = context.colors;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    Widget cols(List<Widget> cells) => Row(
      children: [
        SizedBox(width: 90, child: cells[0]),
        SizedBox(width: 120, child: cells[1]),
        Expanded(child: cells[2]),
        Expanded(flex: 2, child: cells[3]),
        SizedBox(width: 120, child: Align(alignment: Alignment.centerRight, child: cells[4])),
      ],
    );
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: cols([Text('RECEIPT', style: head), Text('DATE', style: head), Text('USER', style: head), Text('REASON', style: head), Text('AMOUNT', style: head)]),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: rows.isEmpty
                ? Center(child: Text('No ${_type.label.toLowerCase()} records in this range', style: TextStyle(color: c.muted)))
                : ListView.builder(
                    itemCount: rows.length,
                    itemExtent: 54,
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      final on = i == _selected;
                      final body = TextStyle(fontSize: 14, color: c.ink);
                      return Material(
                        color: on ? context.colors.voidFill : c.surface,
                        child: InkWell(
                          onTap: () => setState(() => _selected = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: c.rowLine),
                                left: BorderSide(color: on ? AppColors.danger : Colors.transparent, width: 4),
                              ),
                            ),
                            child: cols([
                              Text('#${r.id.toString().padLeft(6, '0')}', style: body.copyWith(fontWeight: FontWeight.w800, color: on ? context.colors.voidInk : c.ink)),
                              Text(_date.format(r.at), style: body.copyWith(color: on ? context.colors.voidInk : c.ink)),
                              Text(r.userName, overflow: TextOverflow.ellipsis, style: body.copyWith(color: on ? context.colors.voidInk : c.ink)),
                              Text(r.reason, overflow: TextOverflow.ellipsis, style: body.copyWith(color: on ? context.colors.voidInk : c.ink)),
                              Text(_rs(r.amountCents), style: body.copyWith(fontWeight: FontWeight.w800, color: on ? context.colors.voidInk : c.ink)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _items(BuildContext context, List<ExceptionRecord> rows) {
    final c = context.colors;
    final items = rows.isEmpty ? const <ExceptionItem>[] : rows[_selected.clamp(0, rows.length - 1)].items;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Exception Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('ITEM NAME', style: head)),
              SizedBox(width: 40, child: Text('QTY', textAlign: TextAlign.center, style: head)),
              SizedBox(width: 90, child: Text('PRICE', textAlign: TextAlign.right, style: head)),
              SizedBox(width: 100, child: Text('AMOUNT', textAlign: TextAlign.right, style: head)),
            ],
          ),
          Divider(color: c.line),
          Expanded(
            child: items.isEmpty
                ? Text('No items for this record', style: TextStyle(color: c.muted))
                : ListView(
                    children: [
                      for (final i in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(i.name, style: TextStyle(color: c.ink))),
                              SizedBox(width: 40, child: Text('${i.quantity}', textAlign: TextAlign.center, style: TextStyle(color: c.ink))),
                              SizedBox(width: 90, child: Text(_rs(i.priceCents), textAlign: TextAlign.right, style: TextStyle(color: c.inkSecondary))),
                              SizedBox(width: 100, child: Text(_rs(i.amountCents), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink))),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
