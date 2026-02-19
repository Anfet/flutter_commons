import 'package:flutter/material.dart';

class AnimatedSwitcherUtils {
  AnimatedSwitcherUtils._();

  static Widget fillHorizontal(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      alignment: Alignment.topCenter,
      fit: StackFit.passthrough,
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  }
}
