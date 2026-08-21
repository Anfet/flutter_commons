import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Public class HoveredDecorator.
///
/// Wraps [child] in a [MouseRegion] and swaps in a hovered look on pointer enter/exit.
/// Supports two independent, composable hover effects:
/// - decoration swap ([decoration] / [hoveredDecoration]) via [AnimatedContainer]
/// - scale ([scale]) via [AnimatedScale]
class HoveredDecorator extends StatefulWidget {
  final Widget child;
  final Decoration? decoration;
  final Decoration? hoveredDecoration;
  final EdgeInsetsGeometry padding;
  final double scale;
  final Duration duration;
  final Curve curve;
  final MouseCursor cursor;

  const HoveredDecorator({
    super.key,
    required this.child,
    this.decoration,
    this.hoveredDecoration,
    this.padding = EdgeInsets.zero,
    this.scale = 1,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.cursor = SystemMouseCursors.basic,
  });

  @override
  State<HoveredDecorator> createState() => _HoveredDecoratorState();
}

class _HoveredDecoratorState extends State<HoveredDecorator> with MountedCheck {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        _isHovered = true;
        markNeedsRebuild();
      },
      onExit: (_) {
        _isHovered = false;
        markNeedsRebuild();
      },
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1,
        duration: widget.duration,
        curve: widget.curve,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          decoration: _isHovered ? widget.hoveredDecoration : widget.decoration,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
