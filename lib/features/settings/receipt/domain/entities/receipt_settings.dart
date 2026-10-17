import 'package:equatable/equatable.dart';

/// What prints above and below every receipt.
class ReceiptSettings extends Equatable {
  const ReceiptSettings({this.header = '', this.footer = '', this.logoPath});

  /// One printed line per text line; the first prints large.
  final String header;
  final String footer;
  final String? logoPath;

  @override
  List<Object?> get props => [header, footer, logoPath];
}
