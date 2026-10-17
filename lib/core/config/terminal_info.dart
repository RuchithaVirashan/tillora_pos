import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Shop and till details shown in headers, footers and receipts.
/// Loaded at startup; Settings updates it when the organization changes.
class TerminalInfo extends Equatable {
  const TerminalInfo({
    required this.companyName,
    required this.terminalName,
    required this.autoPrint,
    required this.ageCheckEnabled,
    required this.maxQuantity,
    this.customerDisplay = false,
    this.cardPayments = true,
  });

  final String companyName;
  final String terminalName;
  final bool autoPrint;
  final bool ageCheckEnabled;
  final int maxQuantity;

  /// Open the customer display with Sales.
  final bool customerDisplay;

  /// The CARD key takes payments.
  final bool cardPayments;

  static const fallback = TerminalInfo(
    companyName: 'Tillora',
    terminalName: 'POS-01',
    autoPrint: false,
    ageCheckEnabled: true,
    maxQuantity: 99,
  );

  TerminalInfo copyWith({
    String? companyName,
    String? terminalName,
    bool? autoPrint,
    bool? ageCheckEnabled,
    int? maxQuantity,
    bool? customerDisplay,
    bool? cardPayments,
  }) => TerminalInfo(
    companyName: companyName ?? this.companyName,
    terminalName: terminalName ?? this.terminalName,
    autoPrint: autoPrint ?? this.autoPrint,
    ageCheckEnabled: ageCheckEnabled ?? this.ageCheckEnabled,
    maxQuantity: maxQuantity ?? this.maxQuantity,
    customerDisplay: customerDisplay ?? this.customerDisplay,
    cardPayments: cardPayments ?? this.cardPayments,
  );

  @override
  List<Object?> get props => [companyName, terminalName, autoPrint, ageCheckEnabled, maxQuantity, customerDisplay, cardPayments];
}

class TerminalInfoHolder extends ValueNotifier<TerminalInfo> {
  TerminalInfoHolder(super.value);
}
