import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  Object? get routeArguments => ModalRoute.of(this)?.settings.arguments;

  Size get size => MediaQuery.of(this).size;

  EdgeInsets get padding => MediaQuery.of(this).padding;

  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  EdgeInsets get viewPaddings => MediaQuery.of(this).viewPadding;
}
