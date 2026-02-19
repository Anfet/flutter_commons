import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

final _kDefaultDuration = 300.milliseconds;

class ScrollFocusable extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final bool isFocused;

  const ScrollFocusable({super.key, required this.child, this.duration, this.isFocused = false});

  @override
  State<ScrollFocusable> createState() => _ScrollFocusableState();
}

class _ScrollFocusableState extends State<ScrollFocusable> {
  ShotReaction? focusReaction;

  @override
  void initState() {
    if (widget.isFocused) {
      focusReaction = ShotReaction.fire();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ScrollFocusable oldWidget) {
    if (!oldWidget.isFocused && widget.isFocused) {
      focusReaction = ShotReaction.fire();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    focusReaction?.consume((_) => scheduleOnNextFrame(() => focusChild(context)));
    return widget.child;
  }

  void focusChild(BuildContext context) {
    Scrollable.ensureVisible(context, duration: widget.duration ?? _kDefaultDuration, alignment: .5);
  }
}
