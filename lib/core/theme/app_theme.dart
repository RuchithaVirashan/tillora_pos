import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Material themes built from the Tillora tokens.
/// Widgets read extra tokens with `Theme.of(context).extension<AppColorsExtension>()`.
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    );
    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        primary: c.primary,
        secondary: AppColors.amber,
        error: AppColors.danger,
        surface: c.surface,
        brightness: brightness,
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(backgroundColor: c.header, foregroundColor: Colors.white, elevation: 0),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: c.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
      extensions: [AppColorsExtension(c)],
    );
  }
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension(this.colors);
  final AppColors colors;

  @override
  AppColorsExtension copyWith({AppColors? colors}) => AppColorsExtension(colors ?? this.colors);

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColorsExtension>()!.colors;
}
