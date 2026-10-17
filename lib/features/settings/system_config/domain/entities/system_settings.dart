import 'package:equatable/equatable.dart';

/// Till-wide settings kept in `sysConfig`.
class SystemSettings extends Equatable {
  const SystemSettings({
    required this.terminalName,
    required this.maxQuantity,
    required this.autoPrint,
    required this.cardPayments,
    required this.ageCheck,
    this.nightTheme = false,
    this.receiptPrinter,
    this.labelPrinter,
    this.paperWidthMm = 80,
  });

  final String terminalName;

  /// Most units of one item a single key press may add.
  final int maxQuantity;
  final bool autoPrint;
  final bool cardPayments;
  final bool ageCheck;

  /// Sales uses the dark night palette.
  final bool nightTheme;

  /// Installed printer names; null uses the system default.
  final String? receiptPrinter;
  final String? labelPrinter;
  final int paperWidthMm;

  SystemSettings copyWith({
    String? terminalName,
    int? maxQuantity,
    bool? autoPrint,
    bool? cardPayments,
    bool? ageCheck,
    bool? nightTheme,
    String? Function()? receiptPrinter,
    String? Function()? labelPrinter,
    int? paperWidthMm,
  }) => SystemSettings(
    terminalName: terminalName ?? this.terminalName,
    maxQuantity: maxQuantity ?? this.maxQuantity,
    autoPrint: autoPrint ?? this.autoPrint,
    cardPayments: cardPayments ?? this.cardPayments,
    ageCheck: ageCheck ?? this.ageCheck,
    nightTheme: nightTheme ?? this.nightTheme,
    receiptPrinter: receiptPrinter == null ? this.receiptPrinter : receiptPrinter(),
    labelPrinter: labelPrinter == null ? this.labelPrinter : labelPrinter(),
    paperWidthMm: paperWidthMm ?? this.paperWidthMm,
  );

  @override
  List<Object?> get props => [terminalName, maxQuantity, autoPrint, cardPayments, ageCheck, nightTheme, receiptPrinter, labelPrinter, paperWidthMm];
}
