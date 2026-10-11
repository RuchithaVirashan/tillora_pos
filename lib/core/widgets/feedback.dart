import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pos_button.dart';
import 'pos_dialog.dart';

/// Short message at the bottom of the screen.
void showToast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: error ? AppColors.danger : AppColors.navy,
        behavior: SnackBarBehavior.floating,
        width: 520,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}

/// Yes/no question in the design's dialog style. Resolves to false on close.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Yes',
  String cancelLabel = 'No',
  bool destructive = false,
  IconData icon = Icons.help_outline_rounded,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.scrim.withValues(alpha: 0.82),
    builder: (context) {
      final c = context.colors;
      return PosDialog(
        title: title,
        icon: icon,
        iconColor: destructive ? AppColors.danger : c.primary,
        iconFill: destructive ? AppColors.dangerTint : c.selection,
        width: 480,
        onClose: () => Navigator.pop(context, false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: TextStyle(fontSize: 17, color: c.inkSecondary, height: 1.4)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: PosButton(
                    label: cancelLabel,
                    height: 58,
                    style: PosButtonStyle.secondary,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PosButton(
                    label: confirmLabel,
                    height: 58,
                    style: destructive ? PosButtonStyle.danger : PosButtonStyle.primary,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
