import 'package:flutter/material.dart';

class InkButton extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const InkButton({
    Key? key,
    this.padding = const EdgeInsets.all(8),
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      clipBehavior: Clip.hardEdge,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
