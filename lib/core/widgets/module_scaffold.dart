import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Page frame for module screens (Product Management, reports): navy 72px
/// header with a back button, optional eyebrow and trailing widget.
class ModuleScaffold extends StatelessWidget {
  const ModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
    this.eyebrow,
    this.trailing,
    this.backLabel = 'Back',
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final Widget body;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    final phone = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          Container(
            height: 72 + top,
            color: AppColors.navy,
            padding: EdgeInsets.fromLTRB(phone ? 12 : 28, top, phone ? 12 : 28, 0),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onBack,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, semanticLabel: backLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null)
                        Text(eyebrow!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFFAFC0D8))),
                      Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// White rounded panel with a hairline border.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.line)),
      child: child,
    );
  }
}

/// A form field with its label above it, as in the design.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Lays fields out two per row on wide screens, one per row on phones.
class FieldGrid extends StatelessWidget {
  const FieldGrid({super.key, required this.children, this.spacing = 14});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth < 520 ? 1 : 2;
        final width = (box.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

/// A value shown in a field-shaped box that cannot be edited.
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField(this.text, {super.key, this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: c.inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: emphasis ? 18 : 15, fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700, color: emphasis ? c.totalInk : c.ink),
      ),
    );
  }
}

/// Tappable date box that opens the date picker. Null shows [placeholder].
class DateField extends StatelessWidget {
  const DateField({super.key, required this.value, required this.onChanged, this.placeholder = 'Select date', this.lastDate});

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String placeholder;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = value;
    return Material(
      color: c.inputFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(now.year - 5),
            lastDate: lastDate ?? DateTime(now.year + 5),
            initialDate: v ?? now,
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  v == null ? placeholder : '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: v == null ? c.muted : c.ink),
                ),
              ),
              Icon(Icons.calendar_today_outlined, size: 18, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Underlined tabs under the module header. Scrolls sideways when the
/// labels do not fit.
class ModuleTabs extends StatelessWidget {
  const ModuleTabs({super.key, required this.labels, required this.selected, required this.onSelect});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, label) in labels.indexed)
              Semantics(
                selected: i == selected,
                button: true,
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: i == selected ? AppColors.amber : Colors.transparent, width: 3)),
                    ),
                    child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: i == selected ? c.ink : c.muted)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
