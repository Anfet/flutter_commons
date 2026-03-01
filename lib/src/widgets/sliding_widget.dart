import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Public class SlidingWidget.
class SlidingWidget extends StatefulWidget {
  final SlidingOrientation orientation;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final SlidingTransitionBuilder? builder;
  final Duration? delay;
  final SlidingPosition slidingPosition;

  const SlidingWidget({
    super.key,
    required this.orientation,
    required this.child,
    required this.duration,
    this.curve = Curves.linear,
    this.builder,
    this.delay,
    this.slidingPosition = SlidingPosition.start,
  });

  @override
  State<SlidingWidget> createState() => _SlidingWidgetState();
}

class _SlidingWidgetState extends State<SlidingWidget> with SingleTickerProviderStateMixin, MountedCheck {
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _animation;
  late final AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: widget.duration);
    _rebuildAnimations();

    if (widget.slidingPosition == SlidingPosition.start) {
      _animationController.value = 0.0;
      _forwardWithDelay();
    }

    if (widget.slidingPosition == SlidingPosition.end) {
      _animationController.stop();
      _animationController.value = 1.0;
    }
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SlidingWidget oldWidget) {
    if (oldWidget.duration != widget.duration) {
      _animationController.duration = widget.duration;
    }

    if (oldWidget.curve != widget.curve || oldWidget.orientation != widget.orientation) {
      _rebuildAnimations();
    }

    if (oldWidget.slidingPosition != widget.slidingPosition && widget.slidingPosition == SlidingPosition.end) {
      _animationController.stop();
      _animationController.value = 1.0;
    }

    if (oldWidget.slidingPosition != SlidingPosition.start && widget.slidingPosition == SlidingPosition.start) {
      _animationController.value = 0.0;
      _forwardWithDelay();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FractionalTranslation(
          translation: _offsetAnimation.value,
          child: widget.builder?.call(context, child, _animation) ?? child,
        );
      },
      child: widget.child,
    );
  }

  void _rebuildAnimations() {
    _animation = CurvedAnimation(parent: _animationController, curve: widget.curve);
    _offsetAnimation = Tween<Offset>(
      begin: _beginOffset,
      end: Offset.zero,
    ).animate(_animation);
  }

  void _forwardWithDelay() {
    (widget.delay ?? Duration.zero).future.then((value) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  Offset get _beginOffset => Offset(
        widget.orientation == SlidingOrientation.leftToRight
            ? -1
            : widget.orientation == SlidingOrientation.rightToLeft
                ? 1
                : 0,
        widget.orientation == SlidingOrientation.topToBottom
            ? -1
            : widget.orientation == SlidingOrientation.bottomToTop
                ? 1
                : 0,
      );
}

/// Public enum SlidingOrientation.
enum SlidingOrientation {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
  ;
}

/// Public enum SlidingPosition.
enum SlidingPosition {
  start,
  end,
  ;
}

typedef SlidingTransitionBuilder = Widget Function(BuildContext context, Widget? child, Animation<double> animation);
