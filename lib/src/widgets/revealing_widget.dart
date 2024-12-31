import 'dart:math';

import 'package:flutter/material.dart';

class RevealingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final AppearingController? controller;

  const RevealingWidget({
    super.key,
    required this.child,
    required this.duration,
    this.controller,
  });

  @override
  State<RevealingWidget> createState() => _RevealingWidgetState();
}

class _RevealingWidgetState extends State<RevealingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: .0, end: 2.0).animate(CurvedAnimation(parent: _controller, curve: Curves.ease));
    _controller.forward();

    widget.controller?.addListener(controllerListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(controllerListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
              ],
              colors: const [Colors.black, Colors.transparent],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: child,
        );
      },
      child: widget.child,
    );
  }

  void controllerListener() {
    _controller.forward(from: 0);
  }
}

class AppearingController with ChangeNotifier {
  void restartAnimation() => notifyListeners();
}
