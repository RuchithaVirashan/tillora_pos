import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../domain/entities/held_sale.dart';
import '../../domain/usecases/hold_usecases.dart';

/// HoldRecall.dc.html. Pops a [HoldOutcome].
class HoldRecallScreen extends StatefulWidget {
  const HoldRecallScreen({super.key, required this.cart});

  final Cart cart;

  @override
  State<HoldRecallScreen> createState() => _HoldRecallScreenState();
}

class _HoldRecallScreenState extends State<HoldRecallScreen> {
  final _logId = getIt<SessionHolder>().current.logId ?? 0;
  final _dateFormat = DateFormat('d MMM y · HH:mm');
  List<HeldSale>? _holds;
  int? _selected;

  /// Set while asking whether to clear the cart: null id = recall all.
  ({int? id})? _pendingRecall;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetHeldSales>()(_logId);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _holds = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _hold() async {
    setState(() => _busy = true);
    final result = await getIt<HoldSale>()(widget.cart, logId: _logId);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      setState(() => _busy = false);
      return showToast(context, failure.message, error: true);
    }
    context.pop(const SaleHeld());
  }

  void _askRecall(int? id) {
    if (widget.cart.isEmpty) {
      _recall(id);
    } else {
      setState(() => _pendingRecall = (id: id));
    }
  }

  Future<void> _recall(int? id) async {
    setState(() => _busy = true);
    final result = await getIt<RecallSale>()(holdId: id, logId: _logId);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        context.pop(SaleRecalled(value));
      case Err(:final failure):
        setState(() => _busy = false);
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final holds = _holds;
    final cart = widget.cart;
    final canHold = !cart.isEmpty && cart.tenders.isEmpty && !cart.refund && !_busy;
    final hasSelection = _selected != null && holds != null && _selected! < holds.length;

    return PosDialog(
      title: 'Hold & Recall',
      width: 1000,
      height: 720,
      headerDivider: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.warningTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warningLine),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.isEmpty
                              ? 'No sale in progress'
                              : 'Current sale · ${cart.itemCount} items · ${Money.lkr(Money.fromCents(cart.totalCents))}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.warningInk),
                        ),
                        const Text('Hold it to serve another customer', style: TextStyle(fontSize: 13, color: AppColors.warningInk)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: Material(
                      color: canHold ? AppColors.orange : c.line,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: canHold ? _hold : null,
                        child: Center(
                          child: Text('Hold',
                              style: TextStyle(color: canHold ? Colors.white : c.muted, fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _table(c, holds)),
            if (_pendingRecall != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.dangerTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dangerLine),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Are you okay to clear cart before recalling?',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dangerInk)),
                    ),
                    PosButton(label: 'Cancel', height: 44, style: PosButtonStyle.secondary, onPressed: () => setState(() => _pendingRecall = null)),
                    const SizedBox(width: 8),
                    PosButton(
                      label: 'Clear Cart',
                      height: 44,
                      style: PosButtonStyle.danger,
                      onPressed: _busy ? null : () => _recall(_pendingRecall!.id),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PosButton(
                    label: 'Recall all hold items',
                    height: 56,
                    style: PosButtonStyle.secondary,
                    onPressed: (holds?.isNotEmpty ?? false) && !_busy ? () => _askRecall(null) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PosButton(
                    label: hasSelection ? 'Recall' : 'Please select hold before recalling',
                    height: 56,
                    style: PosButtonStyle.primary,
                    onPressed: hasSelection && !_busy ? () => _askRecall(holds[_selected!].id) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(AppColors c, List<HeldSale>? holds) {
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: c.tableHead,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text('DATE', style: head)),
                SizedBox(width: 140, child: Text('ITEMS COUNT', textAlign: TextAlign.center, style: head)),
                SizedBox(width: 160, child: Text('TOTAL', textAlign: TextAlign.right, style: head)),
              ],
            ),
          ),
          Expanded(
            child: holds == null
                ? const Center(child: CircularProgressIndicator())
                : holds.isEmpty
                ? Center(child: Text('No sales on hold', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)))
                : ListView.builder(
                    itemCount: holds.length,
                    itemExtent: 60,
                    itemBuilder: (context, i) {
                      final h = holds[i];
                      final on = i == _selected;
                      return Material(
                        color: on ? c.selection : c.surface,
                        child: InkWell(
                          onTap: () => setState(() {
                            _selected = i;
                            _pendingRecall = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: c.rowLine),
                                left: BorderSide(color: on ? AppColors.amber : Colors.transparent, width: 4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(_dateFormat.format(h.heldAt), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink))),
                                SizedBox(width: 140, child: Text('${h.itemCount}', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: c.ink))),
                                SizedBox(
                                  width: 160,
                                  child: Text(Money.lkr(Money.fromCents(h.totalCents)),
                                      textAlign: TextAlign.right, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
                                ),
                              ],
                            ),
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
}
