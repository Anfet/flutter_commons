import 'package:flutter/material.dart';
import 'package:siberian_core/siberian_core.dart';

typedef ThemeWidgetBuilder<T extends CustomTheme> = Widget Function(BuildContext context, T theme);

class ThemeBuilder<T extends CustomTheme> extends StatelessWidget {
  final ThemeWidgetBuilder<T> builder;

  const ThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CustomTheme>(
      valueListenable: Theming.themes,
      builder: (context, theme, child) => builder(context, theme as T),
    );
  }
}
