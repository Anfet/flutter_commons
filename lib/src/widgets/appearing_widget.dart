import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Shows and hides [child] with synchronized size and opacity animation.
///
/// Visibility is child-driven:
/// - `child != null` -> animate in
/// - `child == null` -> animate out
class AppearingWidget extends StatefulWidget {
  /// Animation duration for both size and opacity.
  final Duration? duration;

  /// Curve used for size interpolation.
  final Curve? sizeCurve;

  /// Curve used for opacity interpolation.
  final Curve? opacityCurve;

  /// Axis used for size animation.
  final Axis axis;

  /// Alignment for animated content.
  final Alignment alignment;

  /// Child to render. `null` means hidden.
  final Widget? child;

  /// Creates an [AppearingWidget].
  const AppearingWidget({
    super.key,
    required this.alignment,
    this.child,
    this.duration,
    this.sizeCurve,
    this.opacityCurve,
    this.axis = Axis.vertical,
  });

  @override
  State<AppearingWidget> createState() => _AppearingWidgetState();
}

class _AppearingWidgetState extends State<AppearingWidget> with MountedCheck, SingleTickerProviderStateMixin {
  Widget? _displayedChild;
  late final AnimationController _controller;

  bool get _hasInputChild => widget.child != null;

  Duration get _duration => widget.duration ?? 300.milliseconds;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: _duration);
    _controller.addStatusListener(_onStatusChanged);
    _displayedChild = widget.child;
    _controller.value = _hasInputChild ? 1.0 : 0.0;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AppearingWidget oldWidget) {
    if (oldWidget.duration != widget.duration) {
      _controller.duration = _duration;
    }

    if (_hasInputChild) {
      _displayedChild = widget.child;
      _controller.forward();
    } else if (oldWidget.child != null) {
      _controller.reverse();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _controller.dispose();
    _displayedChild = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedChild == null) {
      return EmptyBox();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sizeValue = (widget.sizeCurve ?? Curves.easeOut).transform(_controller.value);
        final opacityValue = (widget.opacityCurve ?? Curves.easeInOut).transform(_controller.value);
        return ClipRect(
          child: Align(
            alignment: widget.alignment,
            widthFactor: widget.axis == Axis.horizontal ? sizeValue : 1.0,
            heightFactor: widget.axis == Axis.vertical ? sizeValue : 1.0,
            child: Opacity(
              opacity: opacityValue,
              child: child,
            ),
          ),
        );
      },
      child: _displayedChild,
    );
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_hasInputChild) {
      _displayedChild = null;
      markNeedsRebuild();
    }
  }
}
