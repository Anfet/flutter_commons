import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  Object? get routeArguments => ModalRoute.of(this)?.settings.arguments;

  Size get size => mediaQuery.size;

  EdgeInsets get padding => mediaQuery.padding;

  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  EdgeInsets get viewPaddings => mediaQuery.viewPadding;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Future ensureVisible({
    Duration? duration,
    Curve? curve,
    ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
    double? alignment,
  }) =>
      Scrollable.ensureVisible(
        this,
        alignment: alignment ?? 0.0,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.linear,
        alignmentPolicy: alignmentPolicy,
      );
}
