import 'package:flutter/material.dart';

class InkButton extends StatelessWidget {
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double? elevation;
  final Widget child;

  const InkButton({
    Key? key,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.elevation,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      clipBehavior: Clip.hardEdge,
      borderRadius: borderRadius,
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
