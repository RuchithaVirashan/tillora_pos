import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/pos_button.dart';

/// Stands in for screens that are designed but not ported yet, so every
/// tile and button leads somewhere honest.
class NotPortedScreen extends StatelessWidget {
  const NotPortedScreen({super.key, required this.title, required this.design});

  final String title;

  /// The artboard in docs/design/project to build it from.
  final String design;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Row(children: [const BrandMark(size: 30, showName: false), const SizedBox(width: 12), Text(title)]),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction_rounded, size: 48, color: c.muted),
                const SizedBox(height: 16),
                Text('$title is not ported yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 8),
                Text('Design: docs/design/project/$design', textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
                const SizedBox(height: 24),
                PosButton(label: 'Back', height: 52, style: PosButtonStyle.primary, onPressed: () => context.canPop() ? context.pop() : context.go('/')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
