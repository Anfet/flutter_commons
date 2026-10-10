import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

/// Public class RevertableProperty.
class RevertableProperty<T> implements StorableProperty<T> {
  late T _value;

  T _initialValue;

  bool _deletePending = false;

  /// Whether [setValue] or [delete] was called since the last load, revert or commit, even with an equal value: a
  /// mutable value changed in place compares equal to itself.
  bool _dirty = false;

  int _mutationRevision = 0;

  final StorableProperty<T> child;

  RevertableProperty(this.child) : _value = child.cachedValue, _initialValue = child.cachedValue;

  bool get hasChanged => _deletePending || _value != _initialValue;

  @override
  FutureOr<T> getValue() async {
    _value = await child.getValue();
    _initialValue = _value;
    _deletePending = false;
    _dirty = false;
    _mutationRevision++;
    return _value;
  }

  @override
  T get cachedValue => _deletePending ? _initialValue : _value;

  /// Stages deletion until [commit]. [revert] cancels the deletion.
  /// The cached value remains the last committed value while deletion is pending.
  @override
  Future<void> delete() async {
    _deletePending = true;
    _dirty = true;
    _mutationRevision++;
  }

  @override
  Future<void> setValue(T val) async {
    _value = val;
    _deletePending = false;
    _dirty = true;
    _mutationRevision++;
  }

  FutureOr<void> revert() {
    _value = _initialValue;
    _deletePending = false;
    _dirty = false;
    _mutationRevision++;
  }

  /// Writes the draft to [child]. Does nothing without changes, so an unloaded property cannot overwrite the stored
  /// value with its default.
  FutureOr<void> commit() async {
    // hasChanged also covers a revert made while an earlier commit was pending.
    if (!_dirty && !hasChanged) {
      return;
    }
    final mutationRevision = _mutationRevision;
    if (_deletePending) {
      await child.delete();
      final committedValue = await child.getValue();
      _initialValue = committedValue;
      // A newer draft (including revert) survives the completed deletion.
      if (_mutationRevision == mutationRevision) {
        _value = committedValue;
        _deletePending = false;
      }
    } else {
      final committedValue = _value;
      await child.setValue(committedValue);
      _initialValue = committedValue;
    }
    if (_mutationRevision == mutationRevision) {
      _dirty = false;
    }
  }

  @override
  FutureOr<bool> exists() => child.exists();
}
