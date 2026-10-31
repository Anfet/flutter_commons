import 'package:flutter/material.dart';

/// Temporary "work in progress" mark over an unfinished block: a large, faint, rotated label that ignores pointers.
///
/// Meant to be stacked over the block, e.g. `Stack(children: [block, const Positioned.fill(child: WorkInProgressWatermark())])`.
/// The default [text] is not localized on purpose: remove the watermark before release.
class WorkInProgressWatermark extends StatelessWidget {
  const WorkInProgressWatermark({
    super.key,
    this.text = 'WORK IN PROGRESS',
    this.style,
    this.color,
    this.fontSize = 64,
    this.fontWeight = FontWeight.w800,
    this.opacity = 0.12,
    this.angle = -0.12,
    this.alignment = Alignment.center,
    this.fit = BoxFit.scaleDown,
    this.clipBehavior = Clip.hardEdge,
    this.ignorePointer = true,
  });

  /// Label shown by the watermark.
  final String text;

  /// Text style merged over the defaults: [fontSize], [fontWeight], [color] and a line height of 1.
  final TextStyle? style;

  /// Label color. Defaults to the theme's `colorScheme.onSurface`. Overridden by a color in [style].
  final Color? color;

  /// Label font size in logical pixels. Overridden by a size in [style].
  final double fontSize;

  /// Label font weight. Overridden by a weight in [style].
  final FontWeight fontWeight;

  /// Label opacity, from 0 (invisible) to 1 (opaque).
  final double opacity;

  /// Label rotation in radians; a negative value turns it counter-clockwise.
  final double angle;

  /// Label position inside the watermark's area.
  final AlignmentGeometry alignment;

  /// How the label is scaled when the area is narrower than the text.
  final BoxFit fit;

  /// How the label is clipped to the watermark's area.
  final Clip clipBehavior;

  /// Whether the watermark lets touches pass through to the widgets below it.
  final bool ignorePointer;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    ).merge(style);

    return IgnorePointer(
      ignoring: ignorePointer,
      child: ClipRect(
        clipBehavior: clipBehavior,
        child: Align(
          alignment: alignment,
          child: Transform.rotate(
            angle: angle,
            child: Opacity(
              opacity: opacity,
              child: FittedBox(
                fit: fit,
                child: Text(text, style: textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
