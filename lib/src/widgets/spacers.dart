import 'package:flutter/widgets.dart';

class VSpacer extends StatelessWidget {
  final double height;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: 1,
        color: color,
        margin: padding,
      );

  const VSpacer(
    this.height, {
    super.key,
    this.color,
    this.padding = EdgeInsets.zero,
  });
}

class HSpacer extends StatelessWidget {
  final double width;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: 1,
        color: color,
        margin: padding,
      );

  const HSpacer(
    this.width, {
    super.key,
    this.color,
    this.padding = EdgeInsets.zero,
  });
}
