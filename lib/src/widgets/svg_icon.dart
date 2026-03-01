import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Small helper widget for rendering an SVG asset icon.
class SvgIcon extends StatelessWidget {
  /// Rendered icon width.
  final double width;

  /// Rendered icon height.
  final double height;

  /// Asset path of the SVG file.
  final String asset;

  /// Optional tint color.
  final Color? color;

  /// Box fit applied to the SVG.
  final BoxFit fit;

  /// Creates an icon with equal [width] and [height] based on [size].
  const SvgIcon(this.asset, {super.key, double size = 24, this.color, this.fit = BoxFit.contain}) : width = size, height = size;

  @override
  /// Builds [SvgPicture.asset] with optional color filter.
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      key: ValueKey(asset),
      asset,
      height: height,
      width: width,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      fit: fit,
    );
  }
}
