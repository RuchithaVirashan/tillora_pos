import 'package:equatable/equatable.dart';

/// Rupees per one unit of each foreign currency, kept by the shop.
class ExchangeRates extends Equatable {
  const ExchangeRates({this.rates = const {}, this.updated});

  static const base = 'LKR';

  /// Currency code → rupees per unit, e.g. 'USD' → 300.25.
  final Map<String, double> rates;
  final DateTime? updated;

  /// [base] first, then the other currencies A–Z.
  List<String> get codes => [base, ...(rates.keys.toList()..sort())];

  double rateOf(String code) => code == base ? 1 : rates[code] ?? 0;

  /// [amount] of [from] in [to], or null when either rate is missing.
  double? convert(double amount, {required String from, required String to}) {
    final a = rateOf(from), b = rateOf(to);
    if (a <= 0 || b <= 0) return null;
    return amount * a / b;
  }

  @override
  List<Object?> get props => [rates, updated];
}
