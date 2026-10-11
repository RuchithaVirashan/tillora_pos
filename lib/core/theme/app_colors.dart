import 'package:material_ui/material_ui.dart';

/// Colour tokens from the Tillora design canvas.
/// Light is the default; [AppColors.dark] is the night-mode sales screen.
@immutable
class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.line,
    required this.ink,
    required this.inkSecondary,
    required this.muted,
    required this.header,
    required this.primary,
    required this.selection,
    required this.keyNumber,
    required this.keyFunction,
    required this.keyFunctionInk,
    required this.quickItem,
    required this.quickItemInk,
  });

  // Brand accents, shared by both themes.
  static const amber = Color(0xFFF5A524);
  static const success = Color(0xFF0B8A5F);
  static const danger = Color(0xFFC0362C);
  static const dangerInk = Color(0xFFA12A21);
  static const dangerTint = Color(0xFFFDECEA);
  static const warningTint = Color(0xFFFFF4DE);
  static const warningInk = Color(0xFF8A5300);
  static const successTint = Color(0xFFE3F5EE);
  static const successInk = Color(0xFF0B6B4A);

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color line;
  final Color ink;
  final Color inkSecondary;
  final Color muted;
  final Color header;
  final Color primary;
  final Color selection;
  final Color keyNumber;
  final Color keyFunction;
  final Color keyFunctionInk;
  final Color quickItem;
  final Color quickItemInk;

  static const light = AppColors(
    background: Color(0xFFEEF1F5),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF6F8FB),
    line: Color(0xFFE1E6ED),
    ink: Color(0xFF0F1B2D),
    inkSecondary: Color(0xFF344054),
    muted: Color(0xFF667085),
    header: Color(0xFF0D2547),
    primary: Color(0xFF163A6B),
    selection: Color(0xFFEDF3FC),
    keyNumber: Color(0xFFFFFFFF),
    keyFunction: Color(0xFFE7EBF1),
    keyFunctionInk: Color(0xFF273449),
    quickItem: Color(0xFFEAF0FA),
    quickItemInk: Color(0xFF163A6B),
  );

  static const dark = AppColors(
    background: Color(0xFF0A101C),
    surface: Color(0xFF111A2A),
    surfaceMuted: Color(0xFF162134),
    line: Color(0xFF22304A),
    ink: Color(0xFFE6EBF2),
    inkSecondary: Color(0xFFC3CDDA),
    muted: Color(0xFF8D99AB),
    header: Color(0xFF060B14),
    primary: Color(0xFF2F6FD6),
    selection: Color(0xFF1A2A45),
    keyNumber: Color(0xFF18233A),
    keyFunction: Color(0xFF212E47),
    keyFunctionInk: Color(0xFFC9D2DF),
    quickItem: Color(0xFF142645),
    quickItemInk: Color(0xFFCFE0FF),
  );
}
