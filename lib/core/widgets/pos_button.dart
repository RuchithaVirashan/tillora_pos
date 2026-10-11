import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Button looks used on the till, taken from Sales.dc.html.
enum PosButtonStyle {
  /// White digit key with a hairline border.
  number,

  /// Grey function key (DEL, X, MENU, PRICE CHECK).
  function,

  /// Solid primary (ENTER, CARD, Login, OK).
  primary,

  /// Solid green (CASH, Pay, OK on reports).
  success,

  /// Solid red (End Shift, confirm void).
  danger,

  /// Red tint (VOID LINE / VOID SALE).
  voidTint,

  /// Amber tint (HOLD).
  holdTint,

  /// Green tint (Rs 500 / Rs 1,000 note keys).
  note,

  /// Transparent with a 2px primary border (OTHER PAYMENT).
  outline,

  /// Transparent with a 2px red border (REFUND).
  outlineDanger,

  /// White with a grey border (Cancel, Reset).
  secondary,
}

/// A large touch-first button. Disabled when [onPressed] is null.
class PosButton extends StatelessWidget {
  const PosButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PosButtonStyle.function,
    this.fontSize,
    this.icon,
    this.height,
    this.radius = AppSpacing.radiusMd,
    this.child,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final PosButtonStyle style;
  final double? fontSize;
  final IconData? icon;
  final double? height;
  final double radius;

  /// Replaces the label/icon content when given (quick item tiles).
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final (fill, ink, border) = enabled ? _paint(c) : (c.line, c.muted, null);

    final content = child ??
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: ink), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: fontSize ?? (style == PosButtonStyle.number ? 28 : 15),
                  fontWeight: style == PosButtonStyle.number ? FontWeight.w700 : FontWeight.w800,
                  height: 1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        );

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        height: height,
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: border ?? BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTouch, minWidth: AppSpacing.minTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, BorderSide?) _paint(AppColors c) => switch (style) {
    PosButtonStyle.number => (c.keyNumber, c.ink, BorderSide(color: c.keyLine)),
    PosButtonStyle.function => (c.keyFunction, c.keyFunctionInk, null),
    PosButtonStyle.primary => (c.primary, Colors.white, null),
    PosButtonStyle.success => (AppColors.success, Colors.white, null),
    PosButtonStyle.danger => (AppColors.danger, Colors.white, null),
    PosButtonStyle.voidTint => (c.voidFill, c.voidInk, BorderSide(color: c.voidLine)),
    PosButtonStyle.holdTint => (c.holdFill, c.holdInk, BorderSide(color: c.holdLine)),
    PosButtonStyle.note => (c.noteFill, c.noteInk, BorderSide(color: c.noteLine)),
    PosButtonStyle.outline => (Colors.transparent, c.outlineInk, BorderSide(color: c.outlineInk, width: 2)),
    PosButtonStyle.outlineDanger => (Colors.transparent, c.voidInk, BorderSide(color: c.voidInk, width: 2)),
    PosButtonStyle.secondary => (c.surface, c.inkSecondary, BorderSide(color: c.keyLine)),
  };
}
