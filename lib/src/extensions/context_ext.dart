import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  Object? get routeArguments => ModalRoute.of(this)?.settings.arguments;

  Size get size => MediaQuery.sizeOf(this);

  EdgeInsets get padding => MediaQuery.paddingOf(this);

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  EdgeInsets get viewPaddings => MediaQuery.viewPaddingOf(this);

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Future ensureVisible({
    Duration? duration,
    Curve? curve,
    ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
    double? alignment,
  }) => Scrollable.ensureVisible(
    this,
    alignment: alignment ?? 0.0,
    duration: duration ?? const Duration(milliseconds: 300),
    curve: curve ?? Curves.linear,
    alignmentPolicy: alignmentPolicy,
  );
}
