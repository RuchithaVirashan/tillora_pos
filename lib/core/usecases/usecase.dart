import '../errors/result.dart';

/// One business action, e.g. `AddItemToCart`, `EndShift`.
/// Lives in a feature's `domain/usecases/` and depends only on domain
/// repository interfaces.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// For use cases that take no input.
final class NoParams {
  const NoParams();
}
