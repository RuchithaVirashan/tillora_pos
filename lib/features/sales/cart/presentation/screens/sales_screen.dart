import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../app/router/routes.dart';
import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/platform/alert_sounds.dart';
import '../../../../../core/platform/customer_display.dart';
import '../../../../../core/responsive/adaptive_layout.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../discount/domain/entities/discount_choice.dart';
import '../../../hold_recall/domain/entities/held_sale.dart';
import '../../../payout/domain/entities/payout_entry.dart';
import '../../../void/domain/repositories/void_repository.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/sellable_item.dart';
import '../../domain/usecases/complete_sale.dart';
import '../../domain/usecases/get_quick_items.dart';
import '../../domain/usecases/print_receipt.dart';
import '../../domain/usecases/record_age_refusal.dart';
import '../../domain/usecases/scan_item.dart';
import '../bloc/sales_cubit.dart';
import '../layouts/sales_layouts.dart';
import '../widgets/sales_actions.dart';
import '../widgets/sales_chrome.dart';

/// Sales.dc.html. Desktop and mobile layouts share one [SalesCubit].
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key, this.dark = false});

  /// Night theme (SalesNight.dc.html).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final session = getIt<SessionHolder>().current;
    final info = getIt<TerminalInfoHolder>().value;
    return BlocProvider(
      create: (_) => SalesCubit(
        scanItem: getIt<ScanItem>(),
        completeSale: getIt<CompleteSale>(),
        getQuickItems: getIt<GetQuickItems>(),
        sounds: getIt<AlertSounds>(),
        printReceipt: getIt<PrintReceipt>(),
        autoPrint: () => getIt<TerminalInfoHolder>().value.autoPrint,
        logId: session.logId ?? 0,
        maxQuantity: info.maxQuantity,
        ageCheckEnabled: info.ageCheckEnabled,
      )..load(),
      child: Theme(
        data: dark ? AppTheme.dark : Theme.of(context),
        child: _SalesView(session: session, info: info),
      ),
    );
  }
}

class _SalesView extends StatefulWidget {
  const _SalesView({required this.session, required this.info});

  final UserSession session;
  final TerminalInfo info;

  @override
  State<_SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<_SalesView> {
  final _focus = FocusNode(debugLabel: 'till');

  SalesCubit get _cubit => context.read<SalesCubit>();
  Cart get _cart => _cubit.state.cart;

  /// The sale on screen still needs finishing (not empty, not completed).
  bool get _inProgress => !_cart.isEmpty && !_cubit.state.saleComplete;

  final _display = getIt<CustomerDisplay>();

  @override
  void initState() {
    super.initState();
    if (widget.info.customerDisplay && _display.isSupported && !_display.isOpen) {
      _display.open().catchError((Object e) => debugPrint('Customer display did not open: $e'));
    }
    _display.show(_frame(const SalesState()));
  }

  @override
  void dispose() {
    // Leave the display on its welcome screen for the next customer.
    _display.show(_frame(const SalesState()));
    _focus.dispose();
    super.dispose();
  }

  /// What the customer display shows for [state].
  DisplayFrame _frame(SalesState state) {
    final cart = state.cart;
    final sign = cart.refund ? -1 : 1;
    return DisplayFrame(
      companyName: widget.info.companyName,
      lines: [
        for (final l in cart.lines)
          DisplayLine(
            name: l.item.description,
            quantity: l.item.source == ItemSource.discount ? 0 : l.quantity,
            priceCents: l.item.priceCents,
            amountCents: l.amountCents * sign,
          ),
      ],
      itemCount: cart.itemCount,
      totalCents: cart.totalCents,
      paidCents: cart.paidCents,
      changeCents: cart.changeCents,
      refund: cart.refund,
      complete: state.saleComplete,
    );
  }

  /// Opens a dialog route and gives the keyboard back to the till after.
  Future<T?> _open<T>(String route, {Object? extra}) async {
    final result = await context.push<T>(route, extra: extra);
    if (mounted) _focus.requestFocus();
    return result;
  }

  void _toast(String message, {bool error = true}) => showToast(context, message, error: error);

  late final _actions = SalesActions(
    voidLine: () async {
      if (_cart.selectedLine == null || _cubit.state.saleComplete) return _toast('Select a line to void');
      final kind = await _open<VoidKind>(Routes.voidReason, extra: VoidRequest(cart: _cart));
      if (kind == VoidKind.line) _cubit.removeSelectedLine();
      if (kind == VoidKind.sale) _cubit.clearSale();
    },
    voidSale: () async {
      if (!_inProgress) return _toast('There is no sale to void');
      final kind = await _open<VoidKind>(Routes.voidReason, extra: VoidRequest(cart: _cart, kind: VoidKind.sale));
      if (kind == VoidKind.line) _cubit.removeSelectedLine();
      if (kind == VoidKind.sale) _cubit.clearSale();
    },
    hold: () async {
      final cart = _cubit.state.saleComplete ? Cart.empty : _cart;
      switch (await _open<HoldOutcome>(Routes.holdRecall, extra: cart)) {
        case SaleHeld():
          _cubit.clearSale();
          if (mounted) _toast('Sale held', error: false);
        case SaleRecalled(:final lines):
          _cubit.loadLines(lines);
        case null:
      }
    },
    priceCheck: () => _open<void>(Routes.priceCheck, extra: _cubit.state.entry),
    otherPayment: () async {
      if (!_inProgress) return _toast('Scan an item first');
      final tender = await _open<Tender>(Routes.otherPayment, extra: _cart);
      if (tender != null) await _cubit.pay(tender);
    },
    noSale: () {
      if (_inProgress) return _toast('Finish or void the current sale first');
      _open<bool>(Routes.noSale);
    },
    transactions: () => _open<void>(Routes.transactions),
    menu: () => _open<void>(Routes.moreFunctions),
    weight: () async {
      final item = await _open<SellableItem>(Routes.weight);
      if (item != null) _cubit.addWeighed(item);
    },
    itemDiscount: () => _discount(wholeSale: false),
    saleDiscount: () => _discount(wholeSale: true),
    moreQuickItems: () async {
      final item = await _open<SellableItem>(Routes.quickItems, extra: _cubit.state.quickItems);
      if (item != null) _cubit.addQuickItem(item);
    },
    payout: () async {
      final entry = await _open<PayoutEntry>(Routes.payout);
      if (entry != null) _cubit.addPayout(entry.name, entry.amountCents);
    },
    logout: () async {
      if (_inProgress &&
          !await confirm(context, title: 'Logout', message: 'The current sale will be cleared. Log out anyway?', destructive: true)) {
        return;
      }
      getIt<SessionHolder>().signOut();
      if (mounted) context.go(Routes.home);
    },
    endShift: () async {
      if (_inProgress) return _toast('Finish or void the current sale first');
      final cents = await _open<int>(Routes.drawerFloat);
      if (cents != null && mounted) context.go(Routes.shiftEnd, extra: cents);
    },
  );

  Future<void> _discount({required bool wholeSale}) async {
    if (_cubit.discountBlocker(wholeSale: wholeSale) case final reason?) return _toast(reason);
    final choice = await _open<DiscountChoice>(Routes.discount, extra: (_cart, wholeSale));
    if (choice != null) _cubit.applyDiscount(choice.percent, wholeSale: choice.wholeSale);
  }

  /// Keyboard-wedge scanners type the code and press Enter.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _cubit.key(SalesCubit.keyEnter);
    } else if (key == LogicalKeyboardKey.backspace) {
      _cubit.key(SalesCubit.keyDelete);
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      final step = key == LogicalKeyboardKey.arrowUp ? -1 : 1;
      if (_cart.lines.isNotEmpty) _cubit.selectLine((_cart.selected + step).clamp(0, _cart.lines.length - 1));
    } else if (event.character case final ch? when RegExp(r'^[0-9A-Za-z.]$').hasMatch(ch)) {
      _cubit.typed(ch);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _askAge(ScanOutcome pending) async {
    final ok = await confirm(
      context,
      title: 'AGE CHECK',
      message: '${pending.item.description} is for customers aged ${pending.item.ageLimit} or over. Is the customer old enough?',
      confirmLabel: 'Yes',
      cancelLabel: 'No',
      icon: Icons.badge_outlined,
    );
    _cubit.resolveAgeCheck(accepted: ok);
    if (!ok) await getIt<RecordAgeRefusal>()(pending.item, logId: widget.session.logId ?? 0);
    if (mounted) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MultiBlocListener(
      listeners: [
        BlocListener<SalesCubit, SalesState>(
          listenWhen: (a, b) => a.cart != b.cart || a.saleComplete != b.saleComplete,
          listener: (context, s) => _display.show(_frame(s)),
        ),
        BlocListener<SalesCubit, SalesState>(
          listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
          listener: (context, s) => _toast(s.notice!.message, error: s.notice!.error),
        ),
        BlocListener<SalesCubit, SalesState>(
          listenWhen: (a, b) => b.pendingAgeCheck != null && a.pendingAgeCheck != b.pendingAgeCheck,
          listener: (context, s) => _askAge(s.pendingAgeCheck!),
        ),
      ],
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: c.background,
          body: BlocBuilder<SalesCubit, SalesState>(
            builder: (context, state) {
              final refund = state.cart.refund;
              return Column(
                children: [
                  AdaptiveLayout(
                    desktop: (_) => SalesHeader(companyName: widget.info.companyName, refund: refund, actions: _actions),
                    mobile: (_) => SalesHeader(companyName: widget.info.companyName, refund: refund, actions: _actions, compact: true),
                  ),
                  if (refund) const RefundBanner(),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: state.busy,
                      child: AdaptiveLayout(
                        desktop: (_) => SalesDesktopLayout(state: state, cubit: _cubit, actions: _actions),
                        mobile: (_) => SalesMobileLayout(state: state, cubit: _cubit, actions: _actions),
                      ),
                    ),
                  ),
                  AdaptiveLayout(
                    desktop: (_) => SalesFooter(
                      loggedInAt: widget.session.loggedInAt,
                      terminal: widget.info.terminalName,
                      autoPrint: getIt<TerminalInfoHolder>().value.autoPrint,
                      userName: widget.session.userName,
                      refund: refund,
                    ),
                    mobile: (_) => const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
