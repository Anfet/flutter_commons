import 'package:flutter/material.dart';

/// A tappable area with Material ink feedback and a single source of geometry.
///
/// The background comes either from [backgroundColor] (painted by the hosting
/// [Material]) or from [decoration] (gradient, image, outline, shadow). Both
/// stay below the splash, so callers do not have to nest `Material`, `Ink` and
/// `InkWell` by hand. When the [child] itself is opaque, [foregroundInk] draws
/// the splash above it instead.
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
  /// the button clips to [clipBehavior], so a border painted underneath it is
  /// shaved off at the corners, and a wrapper has to repeat [borderRadius] and
  /// keep the two in sync by hand.
  final BorderSide? border;

  /// Background painted below the ink: gradient, image, outline or shadow.
  ///
  /// When neither [customBorder] nor [border] is given, the clip and ink shape
  /// are taken from the decoration: [BoxDecoration.borderRadius],
  /// [BoxShape.circle] or [ShapeDecoration.shape]. Cannot be combined with
  /// [backgroundColor]; use the decoration's color instead. A
  /// [BoxDecoration.boxShadow] is painted outside the button, so it is not
  /// affected by [clipBehavior].
  final Decoration? decoration;

  /// How the button clips its child to its shape. Splashes are always bounded
  /// by the ink shape regardless of this value.
  final Clip clipBehavior;

  /// Paints the ink above [child] instead of below it.
  ///
  /// Use it when the child is opaque (an image, a colored card) and would hide
  /// the splash. The ink layer covers the child, so gestures of interactive
  /// widgets inside [child] are taken by the button.
  final bool foregroundInk;

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
    this.decoration,
    this.clipBehavior = Clip.hardEdge,
    this.foregroundInk = false,
    required this.child,
  }) : assert(decoration == null || backgroundColor == null, 'Give the color inside decoration instead of backgroundColor');

  @override
  Widget build(BuildContext context) {
    // `shape` and `borderRadius` cannot both be given to Material.
    final side = border;
    final borderedShape = side == null ? null : RoundedRectangleBorder(side: side, borderRadius: borderRadius ?? BorderRadius.zero);
    final decorationShape = _shapeOf(decoration);
    // A pre-existing outline must not disappear when a caller additionally
    // provides the new InkWell-only custom border. The custom border still
    // controls the ink response; the Material keeps the explicit outline.
    final materialShape = borderedShape ?? customBorder ?? decorationShape;
    final inkShape = customBorder ?? borderedShape ?? decorationShape;

    final insets = padding;
    final paddedChild = insets == null ? child : Padding(padding: insets, child: child);
    final inkWell = _buildInkWell(inkShape, foregroundInk ? null : paddedChild);

    Widget button = Material(
      color: backgroundColor ?? Colors.transparent,
      clipBehavior: clipBehavior,
      borderRadius: materialShape == null ? borderRadius : null,
      shape: materialShape,
      elevation: elevation ?? 0.0,
      child: foregroundInk
          ? Stack(
              // Passthrough keeps the constraints the button was given, as in
              // the background mode, instead of loosening them for the child.
              fit: StackFit.passthrough,
              children: [
                paddedChild,
                // Ink is painted on the nearest Material below the InkWell, so
                // a second transparent one is needed above the child.
                Positioned.fill(
                  child: Material(type: MaterialType.transparency, child: inkWell),
                ),
              ],
            )
          : inkWell,
    );

    // Painted outside the Material so the ink lands on top of it and the
    // Material clip does not cut a box shadow.
    final background = decoration;
    if (background != null) {
      button = DecoratedBox(decoration: background, child: button);
    }
    return button;
  }

  Widget _buildInkWell(ShapeBorder? inkShape, Widget? child) {
    return InkWell(
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
      child: child,
    );
  }

  // The outline of the decoration is painted by the decoration itself, so the
  // derived shape carries geometry only.
  ShapeBorder? _shapeOf(Decoration? decoration) {
    return switch (decoration) {
      ShapeDecoration(:final shape) => shape,
      BoxDecoration(shape: BoxShape.circle) => const CircleBorder(),
      BoxDecoration(:final borderRadius?) => RoundedRectangleBorder(borderRadius: borderRadius),
      _ => null,
    };
  }
}
