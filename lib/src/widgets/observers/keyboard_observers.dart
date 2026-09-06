import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:provider/provider.dart';

/// Public class KeyboardVisibility.
class KeyboardVisibility {
  final bool isVisible;
  final double absolutePadding;
  final double percentPadding;

  const KeyboardVisibility({
    required this.isVisible,
    required this.absolutePadding,
    required this.percentPadding,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyboardVisibility &&
          isVisible == other.isVisible &&
          absolutePadding == other.absolutePadding &&
          percentPadding == other.percentPadding;

  @override
  int get hashCode => Object.hash(isVisible, absolutePadding, percentPadding);

  @override
  String toString() {
    return 'KeyboardVisibility{isVisible: $isVisible, absolutePadding: $absolutePadding, percentPadding: $percentPadding}';
  }
}

/// Public class KeyboardVisibilityBuilder.
class KeyboardVisibilityBuilder extends StatelessWidget {
  final ValueWidgetBuilder<KeyboardVisibility>? builder;
  final Widget? child;

  const KeyboardVisibilityBuilder({
    super.key,
    this.child,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<KeyboardVisibility>(
      child: child,
      builder: (BuildContext context, KeyboardVisibility visibility, Widget? child) {
        return Padding(
          padding: EdgeInsets.only(bottom: visibility.absolutePadding),
          child: builder?.call(context, visibility, child) ?? child ?? EmptyBox(),
        );
      },
    );
  }
}

/// Public class KeyboardVisibilityObserver.
class KeyboardVisibilityObserver extends StatefulWidget {
  final Widget child;

  const KeyboardVisibilityObserver({super.key, required this.child});

  @override
  State<KeyboardVisibilityObserver> createState() => _KeyboardVisibilityObserverState();

  static final StreamController<KeyboardVisibility> _controller = StreamController.broadcast();

  static Stream<KeyboardVisibility> get stream => _controller.stream;
}

class _KeyboardVisibilityObserverState extends State<KeyboardVisibilityObserver> with WidgetsBindingObserver {
  KeyboardVisibility? _visibility;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateVisibility();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateVisibility();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _visibility!,
      child: widget.child,
      updateShouldNotify: (previous, current) => previous != current,
    );
  }

  void _updateVisibility() {
    final mediaQuery = context.mediaQuery;
    final height = mediaQuery.size.height;
    final percentPadding = height == 0.0 ? 0.0 : mediaQuery.viewInsets.bottom / height;
    final visibility = KeyboardVisibility(
      isVisible: percentPadding > 0.0,
      absolutePadding: mediaQuery.viewInsets.bottom,
      percentPadding: percentPadding,
    );
    if (_visibility == visibility) {
      return;
    }
    _visibility = visibility;
    KeyboardVisibilityObserver._controller.add(visibility);
    if (mounted) {
      setState(() {});
    }
  }
}
