import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/module_scaffold.dart';

/// One tile on the Product Management screen and the panel it opens.
class ProductTool {
  const ProductTool({
    required this.name,
    required this.title,
    required this.note,
    required this.icon,
    required this.ink,
    required this.fill,
    required this.accessFlag,
    this.builder,
  });

  final String name;
  final String title;
  final String note;
  final IconData icon;
  final Color ink;
  final Color fill;
  final String accessFlag;

  /// Null when the tool is not available yet; [note] explains why.
  final WidgetBuilder? builder;
}

/// ProductMgt.dc.html: tool tiles on the left, the selected tool's panel on
/// the right. Tools are passed in so each stays its own feature.
class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key, required this.tools, required this.onBack});

  final List<ProductTool> tools;
  final VoidCallback onBack;

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _access = getIt<SessionHolder>().value?.access;
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final tiles = _Tiles(tools: widget.tools, selected: _selected, horizontal: phone, onSelect: (i) => setState(() => _selected = i));
    final panel = _ToolPanel(key: ValueKey(_selected), tool: widget.tools[_selected], allowed: _access?.can(widget.tools[_selected].accessFlag) ?? false);
    return ModuleScaffold(
      title: 'Product Management',
      onBack: widget.onBack,
      backLabel: 'Back to home',
      body: Padding(
        padding: EdgeInsets.all(phone ? 12 : 26),
        child: phone
            ? Column(children: [SizedBox(height: 120, child: tiles), const SizedBox(height: 12), Expanded(child: panel)])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [SizedBox(width: 520, child: tiles), const SizedBox(width: 20), Expanded(child: panel)],
              ),
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.tools, required this.selected, required this.horizontal, required this.onSelect});

  final List<ProductTool> tools;
  final int selected;
  final bool horizontal;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tile(int i) => _Tile(tool: tools[i], selected: i == selected, onTap: () => onSelect(i));
    if (horizontal) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(width: 150, child: tile(i)),
      );
    }
    final rows = (tools.length / 2).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(r * 2)),
                const SizedBox(width: 14),
                Expanded(child: r * 2 + 1 < tools.length ? tile(r * 2 + 1) : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tool, required this.selected, required this.onTap});

  final ProductTool tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: c.surface,
        elevation: selected ? 6 : 0,
        shadowColor: c.primary.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? c.primary : c.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: tool.fill, borderRadius: BorderRadius.circular(14)),
                  child: Icon(tool.icon, color: tool.ink),
                ),
                Text(tool.name, maxLines: 2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolPanel extends StatelessWidget {
  const _ToolPanel({super.key, required this.tool, required this.allowed});

  final ProductTool tool;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final builder = tool.builder;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tool.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
          const SizedBox(height: 4),
          Text(tool.note, style: TextStyle(fontSize: 14, color: c.muted)),
          const SizedBox(height: 20),
          Expanded(
            child: !allowed
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text('You do not have access to ${tool.name}.', style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700)),
                  )
                : builder == null
                ? const SizedBox.shrink()
                : builder(context),
          ),
        ],
      ),
    );
  }
}
