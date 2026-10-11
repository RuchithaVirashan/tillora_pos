import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Big right-aligned amount box above a keypad (72px, 2px primary border).
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({super.key, required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted)),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          value: text,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.primary, width: 2),
            ),
            child: FittedBox(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small labelled figure box (TOTAL / PAID / CHANGE, report summaries).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.fill,
    this.ink,
    this.labelInk,
    this.valueSize = 22,
  });

  final String label;
  final String value;
  final Color? fill;
  final Color? ink;
  final Color? labelInk;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: fill ?? c.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: labelInk ?? ink ?? c.muted),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w800,
                color: ink ?? c.ink,
                letterSpacing: -0.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
