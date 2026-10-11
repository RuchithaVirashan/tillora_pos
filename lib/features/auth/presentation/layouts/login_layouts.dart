import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/terminal_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/pos_button.dart';
import '../../domain/entities/login_module.dart';
import '../bloc/login_cubit.dart';

/// Navy brand panel on the left, form card centred on the right.
class LoginDesktopLayout extends StatelessWidget {
  const LoginDesktopLayout({super.key, required this.module, required this.info, required this.form});

  final LoginModule module;
  final TerminalInfo info;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 560, child: _BrandPanel(module: module, info: info)),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(width: 460, child: form),
            ),
          ),
        ),
      ],
    );
  }
}

class LoginMobileLayout extends StatelessWidget {
  const LoginMobileLayout({super.key, required this.module, required this.info, required this.form});

  final LoginModule module;
  final TerminalInfo info;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.navy,
          padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 20),
          child: Row(
            children: [
              const BrandMark(size: 36, nameSize: 20),
              const Spacer(),
              _Badge(module.badge),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: form)),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.module, required this.info});

  final LoginModule module;
  final TerminalInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const BrandMark(size: 44, nameSize: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Badge(module.badge),
              const SizedBox(height: 18),
              Text(
                info.companyName,
                style: const TextStyle(fontSize: 52, height: 1.08, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(module.note, style: const TextStyle(fontSize: 18, height: 1.55, color: Color(0xFFC7D4E6))),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _InfoChip(label: 'Terminal', child: Text(info.terminalName, style: _chipValue))),
              const SizedBox(width: 12),
              const Expanded(
                child: _InfoChip(
                  label: 'Database',
                  child: Row(
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: AppColors.live),
                      SizedBox(width: 8),
                      Text('Local · Ready', style: _chipValue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _chipValue = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white);
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: Color(0xFFF8C46A), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFAFC0D8))),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

/// The white form card. Enter in either field submits.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.module, required this.onCancel});

  final LoginModule module;
  final VoidCallback onCancel;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() => context.read<LoginCubit>().submit(_user.text, _password.text);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<LoginCubit>().state;
    final busy = state.status != LoginStatus.idle;

    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
        boxShadow: const [BoxShadow(color: Color(0x40101828), blurRadius: 40, offset: Offset(0, 16), spreadRadius: -20)],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Login to ${widget.module.title}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 6),
            Text('Please fill the form to get started', style: TextStyle(fontSize: 15, color: c.muted)),
            const SizedBox(height: 22),
            if (state.recent.isNotEmpty) ...[
              _label('Recent', c),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in state.recent)
                    InputChip(
                      avatar: CircleAvatar(
                        backgroundColor: c.primary,
                        child: Text(
                          name.length <= 2 ? name.toUpperCase() : name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      label: Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                      selected: _user.text == name,
                      showCheckmark: false,
                      selectedColor: c.selection,
                      side: BorderSide(color: _user.text == name ? c.primary : c.line),
                      tooltip: 'Log in as $name',
                      deleteButtonTooltipMessage: 'Forget $name',
                      onDeleted: () => context.read<LoginCubit>().forget(name),
                      onPressed: () {
                        setState(() => _user.text = name);
                        _password.clear();
                        _passwordFocus.requestFocus();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            _label('User Name', c),
            TextField(
              controller: _user,
              autofocus: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              decoration: _decoration('User Name', Icons.person_outline_rounded),
            ),
            const SizedBox(height: 18),
            _label('Password', c),
            TextField(
              controller: _password,
              focusNode: _passwordFocus,
              obscureText: state.obscure,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              decoration: _decoration('Password', Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  tooltip: state.obscure ? 'Show password' : 'Hide password',
                  icon: Icon(state.obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: context.read<LoginCubit>().toggleObscure,
                ),
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: c.voidFill, borderRadius: BorderRadius.circular(12)),
                child: Text(state.error!, style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 22),
            PosButton(
              label: busy ? 'Logging in…' : 'Login',
              icon: busy ? null : Icons.arrow_forward_rounded,
              height: 60,
              radius: 16,
              fontSize: 17,
              style: PosButtonStyle.primary,
              onPressed: busy ? null : _submit,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.onCancel,
              child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.inkSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, AppColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.inkSecondary)),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
  );
}
