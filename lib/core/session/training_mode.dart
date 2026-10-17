import 'package:flutter/foundation.dart';

/// Practice selling for new staff. While on, sales run as normal on screen
/// but are not saved, stock and the drawer are left alone, voids are not
/// logged, and No Sale, Cash Lift and Hold are unavailable. Always off when
/// the app starts.
class TrainingMode extends ValueNotifier<bool> {
  TrainingMode() : super(false);

  /// Stands in for the transaction id of a practice sale.
  static const practiceSaleId = 0;

  static String unavailable(String what) => '$what is not available in Training Mode';
}
