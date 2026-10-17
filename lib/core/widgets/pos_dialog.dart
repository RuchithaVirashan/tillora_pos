import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// White rounded dialog card from the design (28px radius, close button
/// top-right). Used inside [DialogPage] routes and [showDialog].
class PosDialog extends StatelessWidget {
  const PosDialog({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.danger,
    this.iconFill,
    this.width = 520,
    this.height,
    this.padding = const EdgeInsets.all(30),
    this.headerDivider = false,
    this.trailing,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  /// Defaults to the danger tint of the current theme.
  final Color? iconFill;
  final double width;
  final double? height;
  final EdgeInsets padding;

  /// Full-width header bar with a bottom border (large dialogs like Hold & Recall).
  final bool headerDivider;
  final Widget? trailing;

  /// Defaults to popping the route with no result.
  final VoidCallback? onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxHeight = MediaQuery.sizeOf(context).height - 32;
    final header = Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: context.tone(iconColor, iconFill ?? c.voidFill).fill, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: context.tone(iconColor, iconFill ?? c.voidFill).ink, size: 26),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.ink)),
              if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 13, color: c.muted)),
            ],
          ),
        ),
        ?trailing,
        const SizedBox(width: 8),
        CloseSquareButton(onPressed: onClose ?? () => Navigator.of(context).maybePop()),
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          elevation: 24,
          shadowColor: Colors.black54,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SizedBox(
              width: width,
              height: height == null ? null : math.min(height!, maxHeight),
              child: headerDivider
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                          child: header,
                        ),
                        Flexible(fit: height == null ? FlexFit.loose : FlexFit.tight, child: child),
                      ],
                    )
                  : Padding(
                      padding: padding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [header, const SizedBox(height: 16), Flexible(child: child)],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class CloseSquareButton extends StatelessWidget {
  const CloseSquareButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.close_rounded, color: c.inkSecondary, semanticLabel: 'Close'),
        ),
      ),
    );
  }
}

/// A go_router page that shows its child as a modal dialog over the
/// current screen, so dialogs can be routes and return results with
/// `context.pop(result)`.
class DialogPage<T> extends Page<T> {
  const DialogPage({required this.child, this.barrierDismissible = false, super.key});

  final Widget child;
  final bool barrierDismissible;

  @override
  Route<T> createRoute(BuildContext context) => DialogRoute<T>(
    context: context,
    settings: this,
    barrierDismissible: barrierDismissible,
    barrierColor: AppColors.scrim.withValues(alpha: 0.82),
    useSafeArea: true,
    builder: (_) => child,
  );
}
