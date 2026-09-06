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

  /// Shape used by the transparent [Material] that hosts ink effects from a
  /// direct [InkWell] child.
  ///
  /// The default is null, preserving the existing rectangular, unclipped
  /// material surface. Supply this together with [clipBehavior] when the
  /// decoration and ink response need the same non-rectangular boundary.
  final ShapeBorder? shape;

  /// How the material surface clips [shape].
  ///
  /// Defaults to [Clip.none] to preserve existing visuals.
  final Clip clipBehavior;

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
    this.shape,
    this.clipBehavior = Clip.none,
  });

  @override
  State<HoveredDecorator> createState() => _HoveredDecoratorState();
}

class _HoveredDecoratorState extends State<HoveredDecorator> with MountedCheck {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHovered ? widget.scale : 1,
      duration: widget.duration,
      curve: widget.curve,
      child: MouseRegion(
        cursor: widget.cursor,
        onEnter: (_) {
          _isHovered = true;
          markNeedsRebuild();
        },
        onExit: (_) {
          _isHovered = false;
          markNeedsRebuild();
        },
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          decoration: _isHovered ? widget.hoveredDecoration : widget.decoration,
          child: Material(
            color: Colors.transparent,
            shape: widget.shape,
            clipBehavior: widget.clipBehavior,
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
