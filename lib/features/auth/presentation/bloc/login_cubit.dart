import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/session/user_session.dart';
import '../../domain/entities/login_module.dart';
import '../../domain/usecases/login_user.dart';

enum LoginStatus { idle, busy, success }

class LoginState extends Equatable {
  const LoginState({this.status = LoginStatus.idle, this.error, this.obscure = true, this.recent = const []});

  final LoginStatus status;
  final String? error;
  final bool obscure;

  /// User names used on this device, most recent first.
  final List<String> recent;

  LoginState copyWith({LoginStatus? status, String? error, bool? obscure, List<String>? recent}) => LoginState(
    status: status ?? this.status,
    error: error,
    obscure: obscure ?? this.obscure,
    recent: recent ?? this.recent,
  );

  @override
  List<Object?> get props => [status, error, obscure, recent];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._login, this._recent, this._forget, this._session, this.module) : super(const LoginState()) {
    _recent().then((names) {
      if (!isClosed) emit(state.copyWith(recent: names, error: state.error));
    });
  }

  final LoginUser _login;
  final GetRecentUserNames _recent;
  final ForgetUserName _forget;
  final SessionHolder _session;
  final LoginModule module;

  Future<void> forget(String userName) async {
    await _forget(userName);
    emit(state.copyWith(recent: [...state.recent]..remove(userName), error: state.error));
  }

  void toggleObscure() => emit(state.copyWith(obscure: !state.obscure, error: state.error));

  Future<void> submit(String userName, String password) async {
    if (state.status == LoginStatus.busy) return;
    emit(state.copyWith(status: LoginStatus.busy));
    final result = await _login(LoginParams(userName: userName, password: password, module: module));
    switch (result) {
      case Ok(:final value):
        _session.signIn(value);
        emit(state.copyWith(status: LoginStatus.success));
      case Err(:final failure):
        emit(state.copyWith(status: LoginStatus.idle, error: failure.message));
    }
  }
}
