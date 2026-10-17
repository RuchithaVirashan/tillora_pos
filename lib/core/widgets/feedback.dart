import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pos_button.dart';
import 'pos_dialog.dart';

OverlayEntry? _currentToast;

/// Short message in the top-right corner, below the header. A new message
/// replaces the one showing; tap to dismiss early.
void showToast(BuildContext context, String message, {bool error = false}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _currentToast?.remove();
  late final OverlayEntry entry;
  void dismiss() {
    if (_currentToast == entry) _currentToast = null;
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.paddingOf(context).top + 76,
      right: 16,
      child: _Toast(message: message, error: error, onDone: dismiss),
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.error, required this.onDone});

  final String message;
  final bool error;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))..forward();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: widget.error ? 4 : 3), _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _anim.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.error ? AppColors.danger : AppColors.success;
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut)),
        child: Semantics(
          liveRegion: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width - 32).clamp(200, 420)),
            child: Material(
              color: fill,
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _close,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(widget.message, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        iconFill: destructive ? context.colors.voidFill : c.selection,
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
