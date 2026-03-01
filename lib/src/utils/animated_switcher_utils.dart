import 'package:flutter/material.dart';

/// Helpers for custom [AnimatedSwitcher] transition layouts.
class AnimatedSwitcherUtils {
  AnimatedSwitcherUtils._();

  /// Places current and previous children in a top-aligned stack that fills
  /// available horizontal space.
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

  /// Places current and previous children in a top-aligned stack that fills
  /// available horizontal space.
  static Widget fill(Widget? currentChild, List<Widget> previousChildren) => fillHorizontal(currentChild, previousChildren);
}
