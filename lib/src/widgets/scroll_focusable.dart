import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

final _kDefaultDuration = 300.milliseconds;

/// Scrolls [child] into view when [focus] changes from `false` to `true`.
class ScrollFocusable extends StatefulWidget {
  /// Target child to make visible.
  final Widget child;

  /// Edge-trigger flag. `false -> true` runs `Scrollable.ensureVisible`.
  final bool focus;

  /// Scroll animation duration.
  final Duration? duration;

  /// Optional delay before focus action.
  final Duration? delay;

  /// Scroll animation curve.
  final Curve curve;

  /// Final alignment in viewport (`0..1`).
  final double alignment;

  /// Alignment policy passed to `Scrollable.ensureVisible`.
  final ScrollPositionAlignmentPolicy? alignmentPolicy;

  /// Optional callback called after focus action is scheduled.
  final VoidCallback? onFocused;

  /// Creates a [ScrollFocusable] wrapper.
  const ScrollFocusable({
    super.key,
    required this.child,
    this.focus = false,
    this.duration,
    this.delay,
    this.curve = Curves.ease,
    this.alignment = .5,
    this.alignmentPolicy,
    this.onFocused,
  });

  @override
  State<ScrollFocusable> createState() => _ScrollFocusableState();
}

class _ScrollFocusableState extends State<ScrollFocusable> {
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.focus) {
      scheduleOnNextFrame(_scheduleFocus);
    }
  }

  @override
  void didUpdateWidget(covariant ScrollFocusable oldWidget) {
    if (!oldWidget.focus && widget.focus) {
      _scheduleFocus();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _scheduleFocus() {
    final runId = ++_runId;
    final delay = widget.delay ?? Duration.zero;
    delay.future.then((_) {
      if (!mounted || runId != _runId || !widget.focus) {
        return;
      }
      _focusChild(context);
      widget.onFocused?.call();
    });
  }

  void _focusChild(BuildContext context) {
    Scrollable.ensureVisible(
      context,
      duration: widget.duration ?? _kDefaultDuration,
      curve: widget.curve,
      alignment: widget.alignment,
      alignmentPolicy: widget.alignmentPolicy ?? ScrollPositionAlignmentPolicy.explicit,
    );
  }
}
