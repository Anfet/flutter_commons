import 'package:flutter/foundation.dart';

/// A derived [ValueListenable] produced from another listenable via mapping.
///
/// Dispose this object when it is no longer needed to detach its listener from
/// the source.
class MappedValueListenable<X, Y> extends ChangeNotifier implements ValueListenable<Y> {
  /// Source value listenable.
  final ValueListenable<X> source;

  /// Mapping function converting source value into output value.
  final Y Function(X value) mapper;

  Y _value;
  bool _disposed = false;

  /// Current mapped value.
  @override
  Y get value => _value;

  /// Creates mapped listenable and immediately computes initial mapped value.
  MappedValueListenable(this.source, this.mapper) : _value = mapper(source.value) {
    source.addListener(_onSourceChanged);
  }

  void _onSourceChanged() {
    final next = mapper(source.value);
    if (next == _value) {
      return;
    }

    _value = next;
    notifyListeners();
  }

  /// Detaches from [source] and releases listeners.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    source.removeListener(_onSourceChanged);
    super.dispose();
  }
}

extension ValueListenableMapExt<X> on ValueListenable<X> {
  /// Maps this listenable into a derived listenable with another value type.
  ///
  /// Returned object should be disposed when no longer used.
  MappedValueListenable<X, Y> mapValue<Y>(Y Function(X value) mapper) => MappedValueListenable<X, Y>(this, mapper);
}
