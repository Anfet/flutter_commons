import 'package:flutter/material.dart';

/// Tappable wrapper that shrinks and dims its child while a finger is down.
///
/// Draws no ink: the child itself is the feedback, so photos and rounded tiles are never cut by a splash.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.onTap, required this.child, this.scale = 0.97, this.opacity = 0.9});

  /// Null disables the press effect and the tap.
  final VoidCallback? onTap;

  /// Child scale while pressed.
  final double scale;

  /// Child opacity while pressed.
  final double opacity;

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  static const _duration = Duration(milliseconds: 120);

  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;

    // The pointer listener reacts on touch-down, before the tap wins the gesture arena against the enclosing scroll;
    // a drag then cancels the tap and releases the press.
    return Semantics(
      button: true,
      enabled: isEnabled,
      child: Listener(
        onPointerDown: isEnabled ? (_) => _setPressed(true) : null,
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isEnabled ? _onTap : null,
          onTapCancel: () => _setPressed(false),
          child: AnimatedScale(
            scale: _isPressed ? widget.scale : 1,
            duration: _duration,
            curve: Curves.ease,
            child: AnimatedOpacity(opacity: _isPressed ? widget.opacity : 1, duration: _duration, curve: Curves.ease, child: widget.child),
          ),
        ),
      ),
    );
  }

  void _onTap() {
    Feedback.forTap(context);
    widget.onTap?.call();
  }

  void _setPressed(bool isPressed) {
    if (_isPressed == isPressed) return;
    setState(() => _isPressed = isPressed);
  }
}
