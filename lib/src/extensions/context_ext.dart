import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  Object? get routeArguments => ModalRoute.of(this)?.settings.arguments;

  Size get size => mediaQuery.size;

  EdgeInsets get padding => mediaQuery.padding;

  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  EdgeInsets get viewPaddings => mediaQuery.viewPadding;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
}
