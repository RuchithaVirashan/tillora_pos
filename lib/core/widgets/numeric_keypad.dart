import 'package:material_ui/material_ui.dart';

import 'pos_button.dart';

/// Keys that are not digits.
abstract final class PadKey {
  static const delete = 'DEL';
  static const doubleZero = '00';
  static const dot = '.';
}

/// 3-column keypad used by money dialogs (drawer float, other payment, cash lift).
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onKey,
    this.withDot = false,
    this.keyHeight = 62,
    this.spacing = 8,
  });

  final ValueChanged<String> onKey;

  /// `.` instead of `00` in the bottom-left slot.
  final bool withDot;
  final double keyHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final keys = ['7', '8', '9', '4', '5', '6', '1', '2', '3', withDot ? PadKey.dot : PadKey.doubleZero, '0', PadKey.delete];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 4; row++) ...[
          if (row > 0) SizedBox(height: spacing),
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) SizedBox(width: spacing),
                Expanded(child: _key(keys[row * 3 + col])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _key(String label) {
    final isDelete = label == PadKey.delete;
    return PosButton(
      label: label,
      height: keyHeight,
      fontSize: isDelete ? 15 : 22,
      style: isDelete ? PosButtonStyle.function : PosButtonStyle.number,
      semanticLabel: isDelete ? 'Delete' : null,
      onPressed: () => onKey(label),
    );
  }
}

/// Applies a keypad press to a text amount, keeping at most two decimals
/// and [maxLength] characters.
String applyAmountKey(String current, String key, {int maxLength = 10}) {
  if (key == PadKey.delete) return current.isEmpty ? current : current.substring(0, current.length - 1);
  if (key == PadKey.dot && current.contains('.')) return current;
  final next = current.isEmpty && key == PadKey.dot ? '0.' : current + key;
  final dot = next.indexOf('.');
  if (dot >= 0 && next.length - dot - 1 > 2) return current;
  return next.length > maxLength ? current : next;
}
