import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  Object? get routeArguments => ModalRoute.of(this)?.settings.arguments;

  Size get size => MediaQuery.of(this).size;
}
