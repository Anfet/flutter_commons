import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:provider/provider.dart';

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
  String toString() {
    return 'KeyboardVisibility{isVisible: $isVisible, absolutePadding: $absolutePadding, percentPadding: $percentPadding}';
  }
}

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
      builder: (BuildContext context, KeyboardVisibility visibility, Widget? child) {
        return Padding(
          padding: EdgeInsets.only(bottom: visibility.absolutePadding),
          child: builder?.call(context, visibility, child) ?? child ?? EmptyBox(),
        );
      },
    );
  }
}

class KeyboardVisibilityObserver extends StatefulWidget {
  final Widget child;

  const KeyboardVisibilityObserver({super.key, required this.child});

  @override
  State<KeyboardVisibilityObserver> createState() => _KeyboardVisibilityObserverState();

  static StreamController<KeyboardVisibility> _controller = StreamController.broadcast();

  static Stream<KeyboardVisibility> get stream => _controller.stream;
}

class _KeyboardVisibilityObserverState extends State<KeyboardVisibilityObserver> with WidgetsBindingObserver, Logging {
  Size? _originalSize;

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
    setState(() {
      _originalSize = context.mediaQuery.size;
    });
    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    _originalSize ??= context.mediaQuery.size;
    var percentPadding = _originalSize!.height == 0 ? 0.0 : (context.mediaQuery.viewInsets.bottom / _originalSize!.height);

    var visibility =
        KeyboardVisibility(isVisible: percentPadding > 0.0, absolutePadding: context.mediaQuery.viewInsets.bottom, percentPadding: percentPadding);

    try {
      return Provider.value(
        value: visibility,
        child: widget.child,
        updateShouldNotify: (previous, current) => true,
      );
    } finally {
      KeyboardVisibilityObserver._controller.add(visibility);
    }
  }
}
