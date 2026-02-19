import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

class Enabling extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final double disabledOpacity;

  const Enabling({super.key, required this.child, this.enabled = true, this.disabledOpacity = .5});

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : disabledOpacity,
        duration: 500.milliseconds,
        child: child,
      ),
    );
  }
}
