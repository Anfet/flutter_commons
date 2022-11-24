import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../functions.dart';

class OneTimeBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  final ValueCallback<BuildContext>? onFirstBuild;

  OneTimeBuilder({required this.builder, this.onFirstBuild}) : super(key: ValueKey(const Uuid().v1().toString()));

  @override
  State<OneTimeBuilder> createState() => _OneTimeBuilderState();
}

class _OneTimeBuilderState extends State<OneTimeBuilder> {
  bool _isBuilt = false;

  @override
  Widget build(BuildContext context) {
    if (!_isBuilt) {
      widget.onFirstBuild?.call(context);
      _isBuilt = true;
    }
    return widget.builder(context);
  }
}
