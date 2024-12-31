import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

class SlidingWidget extends StatefulWidget {
  final SlidingOrientation orientation;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final SlidingTransitionBuilder? builder;
  final Duration? delay;

  const SlidingWidget({
    super.key,
    required this.orientation,
    required this.child,
    required this.duration,
    this.curve = Curves.linear,
    this.builder,
    this.delay,
  });

  @override
  State<SlidingWidget> createState() => _SlidingWidgetState();
}

class _SlidingWidgetState extends State<SlidingWidget> with SingleTickerProviderStateMixin {
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _animation;
  late final AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _animationController, curve: widget.curve);
    _offsetAnimation = Tween<Offset>(
      begin: Offset(
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
      ),
      end: Offset.zero,
    ).animate(_animation);
    (widget.delay ?? Duration.zero).future.then((value) => _animationController.forward());
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
}

enum SlidingOrientation {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
  ;
}

typedef SlidingTransitionBuilder = Widget Function(BuildContext context, Widget? child, Animation<double> animation);
