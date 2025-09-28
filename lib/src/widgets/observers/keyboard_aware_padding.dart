import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

class KeyboardPadding extends StatelessWidget {
  final Widget? child;

  const KeyboardPadding({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BottomInsetObserver(
      builder: (context, value, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: value),
          child: child ?? EmptyBox(),
        );
      },
      child: child,
    );
  }
}

/// Observes bottom inset and rebuilds the contend when it changes
///
/// remember that [Scaffold]s [resizeToAvoidBottomInset] must be set to [false] to enable this
/// widget updates
class BottomInsetObserver extends StatefulWidget {
  final ValueWidgetBuilder<double> builder;
  final Widget? child;

  const BottomInsetObserver({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  State<BottomInsetObserver> createState() => _BottomInsetObserverState();
}

class _BottomInsetObserverState extends State<BottomInsetObserver> with WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      MediaQuery.of(context).viewInsets.bottom,
      widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
