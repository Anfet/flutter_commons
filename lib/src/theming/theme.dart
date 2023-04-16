import 'package:flutter/material.dart';

abstract class ThemePattern<C extends ThemeColors> {
  abstract final String name;
  abstract final C colors;
  abstract final ThemeData themeData;
}

abstract class ThemeColors {}

class ThemeNotifier<C extends ThemeColors> extends ChangeNotifier {
  final List<ThemePattern<C>> themes;
  ThemePattern<C> _selected;

  ThemePattern<C> get selected => _selected;

  set selected(ThemePattern<C> value) {
    _selected = value;
    notifyListeners();
  }

  ThemeNotifier({
    required this.themes,
    required ThemePattern<C> selected,
  }) : _selected = selected;
}
