/// Operating system helpers. Implemented in `infrastructure/hardware`.
abstract interface class SystemTools {
  /// Opens the system calculator. Returns false where there is none.
  Future<bool> openCalculator();
}
