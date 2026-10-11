import 'failures.dart';

/// Return type of repositories and use cases: either a value or a [Failure].
///
/// ```dart
/// switch (await getProduct(barcode)) {
///   case Ok(:final value): emit(Loaded(value));
///   case Err(:final failure): emit(Failed(failure.message));
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
