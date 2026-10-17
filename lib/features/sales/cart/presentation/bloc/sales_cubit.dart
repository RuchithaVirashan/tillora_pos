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
import '../../domain/usecases/print_receipt.dart';
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
    required this._printReceipt,
    required this.autoPrint,
    required this.logId,
    required this.maxQuantity,
    required this.ageCheckEnabled,
    this.cardPayments = true,
  }) : super(const SalesState());

  final ScanItem _scanItem;
  final CompleteSale _completeSale;
  final GetQuickItems _getQuickItems;
  final AlertSounds _sounds;
  final PrintReceipt _printReceipt;

  /// Read on every sale, so turning Auto Print on or off applies at once.
  final bool Function() autoPrint;
  final int logId;
  final int maxQuantity;
  final bool ageCheckEnabled;

  /// Off when card payments are turned off in System Configuration.
  final bool cardPayments;

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
  ///
  /// An item with no price (a department key) is sold at the price typed on
  /// the keypad first.
  void addQuickItem(SellableItem item) {
    if (item.priceCents > 0) {
      return _accept(ScanOutcome(item: item, expired: item.isExpiredOn(DateTime.now())));
    }
    final typed = double.tryParse(state.entry) ?? 0;
    if (typed <= 0) return _notify('Type the price, then tap ${item.description}', error: true);
    final priced = SellableItem(
      description: item.description,
      barcode: item.barcode,
      priceCents: Money.toCents(typed),
      departmentId: item.departmentId,
      departmentName: item.departmentName,
      vat: item.vat,
      ageLimit: item.ageLimit,
      source: item.source,
    );
    emit(state.copyWith(entry: ''));
    _accept(ScanOutcome(item: priced));
  }

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
      cart: _workingCart.add(outcome.item, outcome.item.source == ItemSource.weighed ? 1 : state.nextQuantity),
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

  /// Why a discount cannot be given right now, or null when it can.
  String? discountBlocker({required bool wholeSale}) {
    final cart = state.cart;
    if (state.saleComplete || cart.isEmpty) return 'Scan an item first';
    if (cart.refund) return 'Discounts cannot be given on a refund';
    if (cart.tenders.isNotEmpty) return 'The sale is already part-paid';
    if (wholeSale) return null;
    final line = cart.selectedLine;
    if (line == null) return 'Select a line to discount';
    if (line.item.source == ItemSource.discount) return 'Cannot add a discount on top of another discount';
    if (line.item.source == ItemSource.payout) return 'Payout lines cannot be discounted';
    return null;
  }

  void applyDiscount(int percent, {required bool wholeSale}) {
    if (discountBlocker(wholeSale: wholeSale) case final reason?) return _notify(reason, error: true);
    if (percent <= 0 || percent > 100) return _notify('Enter a discount between 1 and 100%', error: true);
    final cart = state.cart;
    emit(state.copyWith(cart: wholeSale ? cart.applySaleDiscount(percent) : cart.applyItemDiscount(cart.selected, percent)));
  }

  /// Cash paid out of the drawer, rung up as a negative line.
  void addPayout(String name, int cents) {
    if (state.cart.refund) return _notify('Switch back to SALES to add a payout', error: true);
    final item = SellableItem(
      description: name,
      barcode: '',
      priceCents: -cents,
      departmentId: 0,
      departmentName: 'Payout',
      source: ItemSource.payout,
    );
    emit(state.copyWith(cart: _workingCart.add(item, 1), lastTransactionId: () => null));
  }

  /// A weighed item; [item] already carries the weighed price.
  void addWeighed(SellableItem item) => _accept(ScanOutcome(item: item));

  // ── Payment ───────────────────────────────────────────────────────────

  /// CASH: typed amount if any, else the exact balance.
  Future<void> payCash() => pay(Tender.cash(_typedOrDue()));

  /// CARD: typed amount for a part payment, else the exact balance. As the
  /// second payment it may be more than the balance; the excess is change.
  Future<void> payCard() async {
    if (!cardPayments) return _notify('Card payments are turned off in Settings', error: true);
    return pay(Tender.card(_typedOrDue()));
  }

  int _typedOrDue() {
    final typed = double.tryParse(state.entry);
    return typed != null && typed > 0 ? Money.toCents(typed) : state.cart.dueCents;
  }

  Future<void> pay(Tender tender) async {
    final cart = state.cart;
    if (state.saleComplete || cart.isEmpty) return _notify('Scan an item first', error: true);
    if (tender.amountCents <= 0) return;
    // A first non-cash payment over the balance is not a part payment.
    // On the second payment any excess is given back as cash change.
    if (tender.method != Tender.cashMethod && cart.tenders.isEmpty && tender.amountCents > cart.dueCents) {
      return _notify(
        '${tender.method} cannot be more than the balance of ${Money.lkr(Money.fromCents(cart.dueCents))}',
        error: true,
      );
    }

    // A sale takes at most two payments (Transactions has method1 and
    // method2), so after a part payment the next one must finish it.
    if (cart.tenders.isNotEmpty && tender.amountCents < cart.dueCents) {
      return _notify(
        'Part payment allows two payments. Pay the remaining ${Money.lkr(Money.fromCents(cart.dueCents))} to complete the sale',
        error: true,
      );
    }

    final paid = cart.withTender(tender);
    emit(state.copyWith(cart: paid, entry: ''));
    if (!paid.isPaid) return;

    emit(state.copyWith(busy: true));
    final result = await _completeSale(CompleteSaleParams(paid, logId: logId));
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(busy: false, lastTransactionId: () => value));
        if (autoPrint()) await _print(value);
      case Err(:final failure):
        // Roll back the tender so the cashier can retry.
        emit(state.copyWith(busy: false, cart: cart));
        _notify(failure.message, error: true);
    }
  }

  /// Prints the receipt; a printer problem is reported, the sale stays saved.
  Future<void> _print(int transactionId) async {
    if (await _printReceipt(transactionId) case Err(:final failure)) _notify(failure.message, error: true);
  }

  /// Prints the receipt for the sale just completed again.
  Future<void> reprintLast() async {
    final id = state.lastTransactionId;
    if (id == null) return _notify('No completed sale to print', error: true);
    await _print(id);
  }

  void _notify(String message, {bool error = false}) =>
      emit(state.copyWith(notice: SalesNotice(++_noticeId, message, error: error)));
}
