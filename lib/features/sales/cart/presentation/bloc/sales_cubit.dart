import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/alert_sounds.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/utils/money.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/sellable_item.dart';
import '../../domain/usecases/complete_sale.dart';
import '../../domain/usecases/get_quick_items.dart';
import '../../domain/usecases/scan_item.dart';

/// A one-off message for the screen to show (toast or dialog).
class SalesNotice extends Equatable {
  const SalesNotice(this.id, this.message, {this.error = false});

  final int id;
  final String message;
  final bool error;

  @override
  List<Object?> get props => [id];
}

class SalesState extends Equatable {
  const SalesState({
    this.cart = Cart.empty,
    this.entry = '',
    this.nextQuantity = 1,
    this.quickItems = const [],
    this.busy = false,
    this.lastTransactionId,
    this.pendingAgeCheck,
    this.notice,
  });

  final Cart cart;

  /// Digits typed on the keypad or by a keyboard-wedge scanner.
  final String entry;

  /// Set with `X`; applies to the next item only.
  final int nextQuantity;
  final List<SellableItem> quickItems;
  final bool busy;

  /// Set once the sale is saved. The paid cart stays on screen (showing
  /// change) until the next item starts a new sale.
  final int? lastTransactionId;

  /// An age-restricted item waiting for the cashier to confirm the age.
  final ScanOutcome? pendingAgeCheck;
  final SalesNotice? notice;

  bool get saleComplete => lastTransactionId != null;

  SalesState copyWith({
    Cart? cart,
    String? entry,
    int? nextQuantity,
    List<SellableItem>? quickItems,
    bool? busy,
    int? Function()? lastTransactionId,
    ScanOutcome? Function()? pendingAgeCheck,
    SalesNotice? notice,
  }) => SalesState(
    cart: cart ?? this.cart,
    entry: entry ?? this.entry,
    nextQuantity: nextQuantity ?? this.nextQuantity,
    quickItems: quickItems ?? this.quickItems,
    busy: busy ?? this.busy,
    lastTransactionId: lastTransactionId != null ? lastTransactionId() : this.lastTransactionId,
    pendingAgeCheck: pendingAgeCheck != null ? pendingAgeCheck() : this.pendingAgeCheck,
    notice: notice ?? this.notice,
  );

  @override
  List<Object?> get props => [cart, entry, nextQuantity, quickItems, busy, lastTransactionId, pendingAgeCheck, notice];
}

class SalesCubit extends Cubit<SalesState> {
  SalesCubit({
    required this._scanItem,
    required this._completeSale,
    required this._getQuickItems,
    required this._sounds,
    required this.logId,
    required this.maxQuantity,
    required this.ageCheckEnabled,
  }) : super(const SalesState());

  final ScanItem _scanItem;
  final CompleteSale _completeSale;
  final GetQuickItems _getQuickItems;
  final AlertSounds _sounds;
  final int logId;
  final int maxQuantity;
  final bool ageCheckEnabled;

  int _noticeId = 0;

  static const keyDelete = 'DEL';
  static const keyTimes = 'X';
  static const keyEnter = 'ENTER';
  static const keyResetQty = 'Reset Qty';
  static const _maxEntry = 14;

  Future<void> load() async {
    if (await _getQuickItems(const NoParams()) case Ok(:final value)) {
      emit(state.copyWith(quickItems: value));
    }
  }

  // ── Keypad ────────────────────────────────────────────────────────────

  void key(String k) {
    switch (k) {
      case keyDelete:
        if (state.entry.isNotEmpty) emit(state.copyWith(entry: state.entry.substring(0, state.entry.length - 1)));
      case keyTimes:
        final n = int.tryParse(state.entry) ?? 0;
        if (n > maxQuantity) return _notify('Maximum quantity is $maxQuantity', error: true);
        emit(state.copyWith(nextQuantity: n > 0 ? n : 1, entry: ''));
      case keyResetQty:
        emit(state.copyWith(nextQuantity: 1));
      case keyEnter:
        scan(state.entry);
      default:
        if (state.entry.length < _maxEntry) emit(state.copyWith(entry: state.entry + k));
    }
  }

  /// Characters from a hardware scanner or keyboard.
  void typed(String text) {
    final next = (state.entry + text).replaceAll(RegExp(r'\s'), '');
    emit(state.copyWith(entry: next.length > _maxEntry ? next.substring(0, _maxEntry) : next));
  }

  // ── Items ─────────────────────────────────────────────────────────────

  Future<void> scan(String code) async {
    if (code.trim().isEmpty || state.busy) return;
    emit(state.copyWith(busy: true, entry: ''));
    final result = await _scanItem(ScanParams(
      code,
      cart: _workingCart,
      quantity: state.nextQuantity,
      maxQuantity: maxQuantity,
    ));
    emit(state.copyWith(busy: false));
    switch (result) {
      case Err(:final failure):
        _sounds.play(AlertSound.notFound);
        _notify(failure.message, error: true);
      case Ok(:final value):
        _accept(value);
    }
  }

  /// Quick item tiles skip the lookup but still get the age check.
  void addQuickItem(SellableItem item) => _accept(ScanOutcome(item: item, expired: item.isExpiredOn(DateTime.now())));

  void _accept(ScanOutcome outcome) {
    if (outcome.needsAgeCheck && ageCheckEnabled) {
      _sounds.play(AlertSound.ageCheck);
      emit(state.copyWith(pendingAgeCheck: () => outcome));
      return;
    }
    _add(outcome);
  }

  /// Answer to the age question. A refusal is recorded by the caller.
  void resolveAgeCheck({required bool accepted}) {
    final pending = state.pendingAgeCheck;
    emit(state.copyWith(pendingAgeCheck: () => null));
    if (accepted && pending != null) _add(pending);
  }

  void _add(ScanOutcome outcome) {
    if (outcome.expired) {
      _sounds.play(AlertSound.expired);
      _notify('${outcome.item.description} is past its expiry date', error: true);
    } else if (outcome.stockLeft != null) {
      _sounds.play(AlertSound.warning);
      _notify('Low stock: ${outcome.item.description} will have ${outcome.stockLeft} left');
    }
    emit(state.copyWith(
      cart: _workingCart.add(outcome.item, state.nextQuantity),
      nextQuantity: 1,
      lastTransactionId: () => null,
    ));
  }

  /// A finished sale stays on screen until the next action starts a new one.
  Cart get _workingCart => state.saleComplete ? Cart(refund: state.cart.refund) : state.cart;

  void selectLine(int index) {
    if (!state.saleComplete) emit(state.copyWith(cart: state.cart.select(index)));
  }

  /// Called after the void reason is recorded.
  void removeSelectedLine() {
    final index = state.cart.selected;
    if (index < 0) return;
    emit(state.copyWith(cart: state.cart.removeAt(index)));
  }

  void clearSale() => emit(state.copyWith(cart: Cart(refund: state.cart.refund), entry: '', nextQuantity: 1, lastTransactionId: () => null));

  /// Replaces the cart with a recalled hold.
  void loadLines(List<CartLine> lines) {
    var cart = Cart(refund: state.cart.refund);
    for (final line in lines.reversed) {
      cart = cart.add(line.item, line.quantity);
    }
    emit(state.copyWith(cart: cart, lastTransactionId: () => null));
  }

  void toggleRefund() {
    if (state.cart.tenders.isNotEmpty && !state.saleComplete) {
      return _notify('Finish or void the part-paid sale first', error: true);
    }
    final base = state.saleComplete ? const Cart() : state.cart;
    emit(state.copyWith(cart: base.toggleRefund(), lastTransactionId: () => null));
  }

  // ── Payment ───────────────────────────────────────────────────────────

  /// CASH: typed amount if any, else the exact balance.
  Future<void> payCash() {
    final typed = double.tryParse(state.entry);
    final cents = typed != null && typed > 0 ? Money.toCents(typed) : state.cart.dueCents;
    return pay(Tender.cash(cents));
  }

  /// CARD always takes the exact balance (no cash back on card).
  Future<void> payCard() => pay(Tender.card(state.cart.dueCents));

  Future<void> pay(Tender tender) async {
    final cart = state.cart;
    if (state.saleComplete || cart.isEmpty) return _notify('Scan an item first', error: true);
    if (tender.amountCents <= 0) return;
    if (tender.method != Tender.cashMethod && tender.amountCents > cart.dueCents) {
      return _notify('Only cash can be more than the balance', error: true);
    }

    final paid = cart.withTender(tender);
    emit(state.copyWith(cart: paid, entry: ''));
    if (!paid.isPaid) return;

    emit(state.copyWith(busy: true));
    final result = await _completeSale(CompleteSaleParams(paid, logId: logId));
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(busy: false, lastTransactionId: () => value));
      case Err(:final failure):
        // Roll back the tender so the cashier can retry.
        emit(state.copyWith(busy: false, cart: cart));
        _notify(failure.message, error: true);
    }
  }

  void _notify(String message, {bool error = false}) =>
      emit(state.copyWith(notice: SalesNotice(++_noticeId, message, error: error)));
}
