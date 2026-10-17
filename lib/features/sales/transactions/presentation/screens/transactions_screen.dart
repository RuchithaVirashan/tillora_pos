import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../../cart/domain/usecases/print_receipt.dart';
import '../../domain/entities/shift_transaction.dart';
import '../../domain/usecases/transactions_usecases.dart';

/// Transactions.dc.html: this shift's receipts, details and pay type swap.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _session = getIt<SessionHolder>().current;
  final _time = DateFormat('HH:mm');
  List<ShiftTransaction>? _rows;
  List<PayTypeOption> _payTypes = const [];
  List<TransactionLine>? _lines;
  int _selected = 0;
  bool _swapping = false;

  ShiftTransaction? get _tx => (_rows?.isNotEmpty ?? false) ? _rows![_selected] : null;

  static String _rs(int cents) => '${cents < 0 ? '−' : ''}${Money.lkr(Money.fromCents(cents.abs()))}';
  static String _receipt(int id) => '#${id.toString().padLeft(6, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
    getIt<GetPayTypeOptions>()().then((r) {
      if (r case Ok(:final value) when mounted) setState(() => _payTypes = value);
    });
  }

  Future<void> _load() async {
    final result = await getIt<GetShiftTransactions>()(_session.logId ?? 0);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _rows = value;
          _selected = _selected.clamp(0, value.isEmpty ? 0 : value.length - 1);
        });
        _loadLines();
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _loadLines() async {
    final tx = _tx;
    setState(() => _lines = null);
    if (tx == null) return;
    final result = await getIt<GetTransactionLines>()(tx.id);
    if (!mounted || tx != _tx) return;
    if (result case Ok(:final value)) setState(() => _lines = value);
  }

  Future<void> _swapTo(PayTypeOption option) async {
    final result = await getIt<SwapPayType>()(_session, _tx!, option);
    if (!mounted) return;
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    setState(() => _swapping = false);
    showToast(context, 'Pay type changed to ${option.name}');
    _load();
  }

  Future<void> _print(ShiftTransaction tx) async {
    final result = await getIt<PrintReceipt>()(tx.id, reprint: true);
    if (!mounted) return;
    switch (result) {
      case Ok():
        showToast(context, 'Receipt ${tx.id.toString().padLeft(6, '0')} sent to the printer');
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final terminal = getIt<TerminalInfoHolder>().value.terminalName;
    return PosDialog(
      title: 'Transactions',
      width: 1240,
      height: 800,
      headerDivider: true,
      trailing: phone ? null : Text('This shift · ${_session.userName} · Terminal $terminal', style: TextStyle(fontSize: 13, color: context.colors.muted)),
      child: phone
          ? Column(children: [Expanded(child: _list(context)), SizedBox(height: 360, child: _details(context))])
          : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: _list(context)), SizedBox(width: 420, child: _details(context))]),
    );
  }

  Widget _list(BuildContext context) {
    final c = context.colors;
    final rows = _rows;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    Widget cols(List<Widget> cells) => Row(
      children: [
        SizedBox(width: 100, child: cells[0]),
        SizedBox(width: 70, child: cells[1]),
        Expanded(child: cells[2]),
        SizedBox(width: 130, child: Align(alignment: Alignment.centerRight, child: cells[3])),
        const SizedBox(width: 16),
        SizedBox(width: 80, child: cells[4]),
      ],
    );

    return Column(
      children: [
        Container(
          color: c.tableHead,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: cols([Text('RECEIPT', style: head), Text('TIME', style: head), Text('PAY TYPE', style: head), Text('TOTAL', style: head), Text('TYPE', style: head)]),
        ),
        Expanded(
          child: rows == null
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
              ? Center(child: Text('No transactions this shift', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)))
              : ListView.builder(
                  itemCount: rows.length,
                  itemExtent: 56,
                  itemBuilder: (context, i) {
                    final t = rows[i];
                    final on = i == _selected;
                    final body = TextStyle(fontSize: 15, color: c.ink, fontFeatures: const [FontFeature.tabularFigures()]);
                    return Material(
                      color: on ? c.selection : c.surface,
                      child: InkWell(
                        onTap: () {
                          setState(() => (_selected = i, _swapping = false));
                          _loadLines();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: c.rowLine),
                              left: BorderSide(color: on ? AppColors.amber : Colors.transparent, width: 4),
                            ),
                          ),
                          child: cols([
                            Text(_receipt(t.id), style: body.copyWith(fontWeight: FontWeight.w800)),
                            Text(_time.format(t.at), style: body),
                            Text(t.methodLabel, overflow: TextOverflow.ellipsis, style: body),
                            Text(_rs(t.totalCents), style: body.copyWith(fontWeight: FontWeight.w800)),
                            _KindPill(refund: t.isRefund),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _details(BuildContext context) {
    final c = context.colors;
    final tx = _tx;
    final lines = _lines;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: c.surfaceMuted, border: Border(left: BorderSide(color: c.line))),
      child: tx == null
          ? Center(child: Text('Select a transaction', style: TextStyle(color: c.muted)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Transaction Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(_receipt(tx.id), style: TextStyle(fontWeight: FontWeight.w800, color: c.primary)),
                    const Spacer(),
                    Text(DateFormat('d MMM · HH:mm').format(tx.at), style: TextStyle(color: c.muted)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
                    child: lines == null
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            children: [
                              for (final l in lines)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(l.quantity > 1 ? '${l.description} × ${l.quantity}' : l.description, style: TextStyle(color: c.ink)),
                                      ),
                                      Text(_rs(l.amountCents), style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                                    ],
                                  ),
                                ),
                              Divider(color: c.line),
                              Row(
                                children: [
                                  Text('Total', style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                                  const Spacer(),
                                  Text(_rs(tx.totalCents), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Pay type', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(tx.isPartPay ? 'Part payment' : tx.method, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                  ],
                ),
                // Split payments, overpayments and change: what came from where.
                if (tx.payments.length > 1 || tx.changeCents != 0) ...[
                  const SizedBox(height: 8),
                  _PaymentBreakdown(tx: tx),
                ],
                if (_swapping) ...[
                  const SizedBox(height: 12),
                  Text('Swap type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final o in _payTypes.where((o) => o.name != tx.method))
                        PosButton(label: o.name, height: 44, style: PosButtonStyle.secondary, onPressed: () => _swapTo(o)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PosButton(
                        label: 'Swap Pay type',
                        height: 52,
                        style: PosButtonStyle.secondary,
                        onPressed: tx.isPartPay ? null : () => setState(() => _swapping = !_swapping),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PosButton(
                        label: 'Print Receipt',
                        height: 52,
                        style: PosButtonStyle.secondary,
                        onPressed: () => _print(tx),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: PosButton(label: 'Close', height: 52, style: PosButtonStyle.primary, onPressed: () => context.pop())),
                  ],
                ),
              ],
            ),
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({required this.refund});

  final bool refund;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: refund ? context.colors.voidFill : context.colors.noteFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        refund ? 'Refund' : 'Sale',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: refund ? context.colors.voidInk : context.colors.noteInk),
      ),
    ),
  );
}

/// "Card Rs 300.00 / Cash Rs 1,000.00 / Change −Rs 250.00".
class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({required this.tx});

  final ShiftTransaction tx;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String rs(int cents) => '${cents < 0 ? '−' : ''}${Money.lkr(Money.fromCents(cents.abs()))}';
    Widget row(String label, String value, {bool strong = false, Color? ink}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: ink ?? c.inkSecondary, fontWeight: strong ? FontWeight.w800 : FontWeight.w600))),
          Text(
            value,
            style: TextStyle(
              color: ink ?? c.ink,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
      child: Column(
        children: [
          for (final (i, p) in tx.payments.indexed)
            row(tx.payments.length > 1 ? '${i == 0 ? '1st' : '2nd'} · ${p.method}' : p.method, rs(p.amountCents)),
          if (tx.changeCents != 0) row(tx.isRefund ? 'Returned · Cash' : 'Change · Cash', rs(-tx.changeCents), ink: c.voidInk),
          Divider(height: 12, color: c.line),
          row('Total', rs(tx.totalCents), strong: true),
        ],
      ),
    );
  }
}
