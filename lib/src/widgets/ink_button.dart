import 'package:flutter/material.dart';

/// Public class InkButton.
class InkButton extends StatelessWidget {
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double? elevation;

  /// Outline drawn around the button, inside its [borderRadius].
  ///
  /// Given here rather than by wrapping the button in a decorated container:
  /// the button clips to [Clip.hardEdge], so a border painted underneath it is
  /// shaved off at the corners, and a wrapper has to repeat [borderRadius] and
  /// keep the two in sync by hand.
  final BorderSide? border;

  final Widget child;

  const InkButton({
    super.key,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.elevation,
    this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // `shape` and `borderRadius` cannot both be given to Material, so the
    // shape is only built when there is a border to draw; without one the
    // widget stays exactly as it was.
    final side = border;
    final shape = side == null
        ? null
        : RoundedRectangleBorder(
            side: side,
            borderRadius: borderRadius ?? BorderRadius.zero,
          );

    return Material(
      color: backgroundColor ?? Colors.transparent,
      clipBehavior: Clip.hardEdge,
      borderRadius: shape == null ? borderRadius : null,
      shape: shape,
      elevation: elevation ?? 0.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
