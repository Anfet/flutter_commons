import 'package:flutter/material.dart';

/// Public class InkButton.
class InkButton extends StatelessWidget {
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureLongPressUpCallback? onLongPressUp;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTapCancel;
  final GestureTapCallback? onSecondaryTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final GestureTapDownCallback? onSecondaryTapDown;
  final GestureTapCallback? onSecondaryTapCancel;
  final ValueChanged<bool>? onHighlightChanged;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final Color? splashColor;
  final InteractiveInkFeatureFactory? splashFactory;
  final double? radius;

  /// Boundary used by InkWell's splash, focus, hover, and highlight effects.
  ///
  /// When [border] is also set, that existing outline remains the Material
  /// shape while this property controls the ink response geometry.
  final ShapeBorder? customBorder;
  final bool enableFeedback;
  final bool excludeFromSemantics;
  final FocusNode? focusNode;
  final bool canRequestFocus;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final WidgetStatesController? statesController;
  final Duration? hoverDuration;
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
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressUp,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.onSecondaryTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapCancel,
    this.onHighlightChanged,
    this.onHover,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.overlayColor,
    this.splashColor,
    this.splashFactory,
    this.radius,
    this.customBorder,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
    this.statesController,
    this.hoverDuration,
    this.borderRadius,
    this.backgroundColor,
    this.elevation,
    this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // `shape` and `borderRadius` cannot both be given to Material.
    final side = border;
    final borderedShape = side == null ? null : RoundedRectangleBorder(side: side, borderRadius: borderRadius ?? BorderRadius.zero);
    // A pre-existing outline must not disappear when a caller additionally
    // provides the new InkWell-only custom border. The custom border still
    // controls the ink response; the Material keeps the explicit outline.
    final materialShape = borderedShape ?? customBorder;
    final inkShape = customBorder ?? borderedShape;

    return Material(
      color: backgroundColor ?? Colors.transparent,
      clipBehavior: Clip.hardEdge,
      borderRadius: materialShape == null ? borderRadius : null,
      shape: materialShape,
      elevation: elevation ?? 0.0,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onLongPressUp: onLongPressUp,
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        onSecondaryTap: onSecondaryTap,
        onSecondaryTapUp: onSecondaryTapUp,
        onSecondaryTapDown: onSecondaryTapDown,
        onSecondaryTapCancel: onSecondaryTapCancel,
        onHighlightChanged: onHighlightChanged,
        onHover: onHover,
        mouseCursor: mouseCursor,
        focusColor: focusColor,
        hoverColor: hoverColor,
        highlightColor: highlightColor,
        overlayColor: overlayColor,
        splashColor: splashColor,
        splashFactory: splashFactory,
        radius: radius,
        borderRadius: borderRadius,
        customBorder: inkShape,
        enableFeedback: enableFeedback,
        excludeFromSemantics: excludeFromSemantics,
        focusNode: focusNode,
        canRequestFocus: canRequestFocus,
        onFocusChange: onFocusChange,
        autofocus: autofocus,
        statesController: statesController,
        hoverDuration: hoverDuration,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
