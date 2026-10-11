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
  });

  final String companyName;
  final String terminalName;
  final bool autoPrint;
  final bool ageCheckEnabled;
  final int maxQuantity;

  static const fallback = TerminalInfo(
    companyName: 'Tillora',
    terminalName: 'POS-01',
    autoPrint: false,
    ageCheckEnabled: true,
    maxQuantity: 99,
  );

  @override
  List<Object?> get props => [companyName, terminalName, autoPrint, ageCheckEnabled, maxQuantity];
}

class TerminalInfoHolder extends ValueNotifier<TerminalInfo> {
  TerminalInfoHolder(super.value);
}
