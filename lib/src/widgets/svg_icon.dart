import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final double width;
  final double height;
  final String asset;
  final Color? color;
  final BoxFit fit;

  const SvgIcon(this.asset, {super.key, double size = 24, this.color, this.fit = BoxFit.contain}) : width = size, height = size;

  @override
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
