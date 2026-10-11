import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Radio-style list of large rows (void reasons, no-sale reasons).
class ChoiceList extends StatelessWidget {
  const ChoiceList({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.accent,
    required this.accentFill,
    this.semanticLabel,
  });

  final List<String> options;
  final int? selected;
  final ValueChanged<int> onSelected;
  final Color accent;
  final Color accentFill;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _row(c.ink, c.line, i),
          ],
        ],
      ),
    );
  }

  Widget _row(Color ink, Color line, int i) {
    final on = i == selected;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      child: Material(
        color: on ? accentFill : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: on ? accent : line, width: on ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelected(i),
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                const SizedBox(width: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? accent : const Color(0xFFC3CCD8), width: on ? 6 : 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(options[i], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
