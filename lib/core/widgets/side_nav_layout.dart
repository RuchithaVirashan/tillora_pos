import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'module_scaffold.dart';

/// One entry in a [SideNavLayout] menu. [badge] shows on the right, e.g.
/// a count; [onOpen] set makes it a link that leaves the screen instead
/// of selecting a panel.
class SideNavItem {
  const SideNavItem(this.label, {this.badge, this.onOpen});

  final String label;
  final String? badge;
  final VoidCallback? onOpen;
}

/// A menu of sections on the left and the selected section's panel on the
/// right. On phones the menu becomes a row of chips above the panel.
class SideNavLayout extends StatelessWidget {
  const SideNavLayout({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.child,
    this.navWidth = 300,
    this.scrollPanel = true,
  });

  final List<SideNavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final Widget child;
  final double navWidth;

  /// Wraps [child] in a scroll view; false when the child scrolls itself.
  final bool scrollPanel;

  void _tap(int i) => items[i].onOpen != null ? items[i].onOpen!() : onSelect(i);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final phone = box.maxWidth < 760;
        final panel = Panel(child: scrollPanel ? SingleChildScrollView(child: child) : child);
        if (phone) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (i, item) in items.indexed) ...[
                        ChoiceChip(
                          label: Text(item.badge == null ? item.label : '${item.label} · ${item.badge}'),
                          selected: i == selected,
                          onSelected: (_) => _tap(i),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: panel),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: navWidth,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final on = i == selected && item.onOpen == null;
                    return Material(
                      color: on ? c.selection : c.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: BorderSide(color: on ? c.primary : c.line, width: on ? 2 : 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () => _tap(i),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.label, style: TextStyle(fontWeight: FontWeight.w700, color: on ? c.primary : c.inkSecondary))),
                              if (item.badge != null) Text(item.badge!, style: TextStyle(fontWeight: FontWeight.w800, color: c.muted)),
                              if (item.onOpen != null) Icon(Icons.open_in_new_rounded, size: 16, color: c.muted),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: panel),
            ],
          ),
        );
      },
    );
  }
}

/// An on/off row used across the settings panels.
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({super.key, required this.label, required this.value, required this.onChanged, this.note});

  final String label;
  final String? note;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13), side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
          subtitle: note == null ? null : Text(note!, style: TextStyle(color: c.muted)),
        ),
      ),
    );
  }
}
