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
    required this.rowLine,
    required this.ink,
    required this.inkSecondary,
    required this.muted,
    required this.header,
    required this.headerMuted,
    required this.primary,
    required this.totalInk,
    required this.selection,
    required this.inputFill,
    required this.tableHead,
    required this.keyNumber,
    required this.keyLine,
    required this.keyFunction,
    required this.keyFunctionInk,
    required this.quickItem,
    required this.quickItemInk,
    required this.quickItemSub,
    required this.quickItemLine,
    required this.voidFill,
    required this.voidInk,
    required this.voidLine,
    required this.holdFill,
    required this.holdInk,
    required this.holdLine,
    required this.noteFill,
    required this.noteInk,
    required this.noteLine,
    required this.outlineInk,
  });

  // Brand accents, shared by both themes.
  static const amber = Color(0xFFF5A524);
  static const navy = Color(0xFF0D2547);
  static const success = Color(0xFF0B8A5F);
  static const danger = Color(0xFFC0362C);
  static const dangerDeep = Color(0xFF7E1F18);
  static const dangerInk = Color(0xFFA12A21);
  static const dangerTint = Color(0xFFFDECEA);
  static const dangerLine = Color(0xFFF5C9C4);
  static const warningTint = Color(0xFFFFF4DE);
  static const warningInk = Color(0xFF8A5300);
  static const warningLine = Color(0xFFF3DDB0);
  static const orange = Color(0xFFED6700);
  static const successTint = Color(0xFFE3F5EE);
  static const successInk = Color(0xFF0B6B4A);
  static const live = Color(0xFF34C38F);
  static const scrim = Color(0xFF1A2436);

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color line;
  final Color rowLine;
  final Color ink;
  final Color inkSecondary;
  final Color muted;
  final Color header;
  final Color headerMuted;
  final Color primary;
  final Color totalInk;
  final Color selection;
  final Color inputFill;
  final Color tableHead;
  final Color keyNumber;
  final Color keyLine;
  final Color keyFunction;
  final Color keyFunctionInk;
  final Color quickItem;
  final Color quickItemInk;
  final Color quickItemSub;
  final Color quickItemLine;
  final Color voidFill;
  final Color voidInk;
  final Color voidLine;
  final Color holdFill;
  final Color holdInk;
  final Color holdLine;
  final Color noteFill;
  final Color noteInk;
  final Color noteLine;
  final Color outlineInk;

  static const light = AppColors(
    background: Color(0xFFEEF1F5),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF6F8FB),
    line: Color(0xFFE1E6ED),
    rowLine: Color(0xFFEEF1F5),
    ink: Color(0xFF0F1B2D),
    inkSecondary: Color(0xFF344054),
    muted: Color(0xFF667085),
    header: Color(0xFF0D2547),
    headerMuted: Color(0xFFAFC0D8),
    primary: Color(0xFF163A6B),
    totalInk: Color(0xFF163A6B),
    selection: Color(0xFFEDF3FC),
    inputFill: Color(0xFFF7F9FB),
    tableHead: Color(0xFFF7F9FB),
    keyNumber: Color(0xFFFFFFFF),
    keyLine: Color(0xFFDCE2EA),
    keyFunction: Color(0xFFE7EBF1),
    keyFunctionInk: Color(0xFF273449),
    quickItem: Color(0xFFEAF0FA),
    quickItemInk: Color(0xFF163A6B),
    quickItemSub: Color(0xFF46638F),
    quickItemLine: Color(0xFFD3DEEE),
    voidFill: Color(0xFFFDECEA),
    voidInk: Color(0xFFA12A21),
    voidLine: Color(0xFFF5C9C4),
    holdFill: Color(0xFFFFF4DE),
    holdInk: Color(0xFF8A5300),
    holdLine: Color(0xFFF3DDB0),
    noteFill: Color(0xFFE6F5EE),
    noteInk: Color(0xFF0B6B4A),
    noteLine: Color(0xFFC5E8D7),
    outlineInk: Color(0xFF163A6B),
  );

  static const dark = AppColors(
    background: Color(0xFF0A101C),
    surface: Color(0xFF111A2A),
    surfaceMuted: Color(0xFF162134),
    line: Color(0xFF22304A),
    rowLine: Color(0xFF1B2638),
    ink: Color(0xFFE6EBF2),
    inkSecondary: Color(0xFFC3CDDA),
    muted: Color(0xFF8D99AB),
    header: Color(0xFF060B14),
    headerMuted: Color(0xFF8D99AB),
    primary: Color(0xFF2F6FD6),
    totalInk: Color(0xFF8FB8FF),
    selection: Color(0xFF1A2A45),
    inputFill: Color(0xFF0D1524),
    tableHead: Color(0xFF162134),
    keyNumber: Color(0xFF18233A),
    keyLine: Color(0xFF26344F),
    keyFunction: Color(0xFF212E47),
    keyFunctionInk: Color(0xFFC9D2DF),
    quickItem: Color(0xFF142645),
    quickItemInk: Color(0xFFCFE0FF),
    quickItemSub: Color(0xFF8FAAD6),
    quickItemLine: Color(0xFF22406E),
    voidFill: Color(0xFF351819),
    voidInk: Color(0xFFFF9B90),
    voidLine: Color(0xFF5A2A2A),
    holdFill: Color(0xFF33260F),
    holdInk: Color(0xFFF8C46A),
    holdLine: Color(0xFF57401A),
    noteFill: Color(0xFF0F2E27),
    noteInk: Color(0xFF7FE0B5),
    noteLine: Color(0xFF1C4A3E),
    outlineInk: Color(0xFF8FB8FF),
  );
}
