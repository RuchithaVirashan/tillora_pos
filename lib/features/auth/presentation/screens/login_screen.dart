import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injector.dart';
import '../../../../core/config/terminal_info.dart';
import '../../../../core/responsive/adaptive_layout.dart';
import '../../../../core/session/user_session.dart';
import '../../domain/entities/login_module.dart';
import '../../domain/usecases/login_user.dart';
import '../bloc/login_cubit.dart';
import '../layouts/login_layouts.dart';

/// Login.dc.html. [onSuccess] receives the module so the router can open it.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.module, required this.onSuccess});

  final LoginModule module;
  final void Function(BuildContext context, LoginModule module) onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(getIt<LoginUser>(), getIt<SessionHolder>(), module),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (a, b) => b.status == LoginStatus.success && a.status != b.status,
        listener: (context, _) => onSuccess(context, module),
        child: Scaffold(
          body: ValueListenableBuilder<TerminalInfo>(
            valueListenable: getIt<TerminalInfoHolder>(),
            builder: (context, info, _) {
              final form = LoginForm(module: module, onCancel: () => context.pop());
              return AdaptiveLayout(
                desktop: (_) => LoginDesktopLayout(module: module, info: info, form: form),
                mobile: (_) => LoginMobileLayout(module: module, info: info, form: form),
              );
            },
          ),
        ),
      ),
    );
  }
}
