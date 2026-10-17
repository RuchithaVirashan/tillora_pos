import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/usecases/reset_void_counts.dart';

/// An admin logs in to reset this shift's void and no sale counts.
/// Pops true once reset.
class ResetVoidDialog extends StatefulWidget {
  const ResetVoidDialog({super.key});

  @override
  State<ResetVoidDialog> createState() => _ResetVoidDialogState();
}

class _ResetVoidDialogState extends State<ResetVoidDialog> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    setState(() => _working = true);
    final result = await getIt<ResetVoidCounts>()(userName: _user.text, password: _password.text, session: getIt<SessionHolder>().current);
    if (!mounted) return;
    setState(() => _working = false);
    switch (result) {
      case Ok(:final value):
        showToast(context, 'Void counts reset, approved by $value');
        Navigator.of(context).pop(true);
      case Err(:final failure):
        _password.clear();
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PosDialog(
      title: 'Reset Void Counts',
      subtitle: 'Please login for reset void counts',
      icon: Icons.restart_alt_rounded,
      iconColor: AppColors.danger,
      iconFill: AppColors.dangerTint,
      width: 460,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Void line, void sale and no sale counts for this shift start again from zero. Earlier records stay in Exceptions.',
              style: TextStyle(color: c.inkSecondary),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Admin User Name',
              child: TextField(controller: _user, autofocus: true, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.username]),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Password',
              child: TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _working ? null : _reset(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: PosButton(label: 'Cancel', height: 52, style: PosButtonStyle.secondary, onPressed: () => Navigator.of(context).pop(false))),
                const SizedBox(width: 10),
                Expanded(child: PosButton(label: 'Reset', height: 52, style: PosButtonStyle.danger, onPressed: _working ? null : _reset)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
