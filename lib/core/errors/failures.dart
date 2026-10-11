import 'package:equatable/equatable.dart';

/// What the domain and presentation layers see when something goes wrong.
/// Blocs turn a [Failure] into a message on screen.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class HardwareFailure extends Failure {
  const HardwareFailure(super.message);
}

class FileFailure extends Failure {
  const FileFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
