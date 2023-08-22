import 'package:flutter/cupertino.dart';

mixin MountedStateMixin<S extends StatefulWidget> on State<S> {
  void setStateChecked(VoidCallback func) {
    if (mounted) {
      setState(() => func());
    }
  }
}
