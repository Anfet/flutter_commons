/// Represents an object that holds resources and can release them explicitly.
abstract interface class Disposable {
  /// Releases owned resources (subscriptions, controllers, handles, etc.).
  void dispose();
}
