import 'package:flutter/material.dart';
import 'package:siberian_logger/siberian_logger.dart';

class KeyboardAwarePadding extends StatelessWidget {
  final Widget child;

  const KeyboardAwarePadding({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BottomInsetObserver(
      builder: (context, value, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: value),
          child: child!,
        );
      },
      child: child,
    );
  }
}

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

class _BottomInsetObserverState extends State<BottomInsetObserver> with WidgetsBindingObserver, Logging {
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
