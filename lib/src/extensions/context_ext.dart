import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  dynamic get routeArguments => ModalRoute.of(this)?.settings.arguments;

  Size get mediaQuerySize => MediaQuery.of(this).size;
}
