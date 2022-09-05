import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siberian_core/siberian_core.dart';

typedef ThemeWidgetBuilder<C extends ThemeColors> = Widget Function(
  BuildContext context,
  ThemePattern<C> theme,
  Widget? child,
);

class ThemeBuilder<C extends ThemeColors, S extends Styles> extends StatelessWidget {
  final ThemeNotifier<C>? themeNotifier;
  final ThemeWidgetBuilder<C> builder;

  const ThemeBuilder({
    Key? key,
    required this.builder,
    this.themeNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeNotifier<C>>.value(
      value: themeNotifier ?? Provider.of<ThemeNotifier<C>>(context) ?? throwIfNull("No themeNotifier provided or set"),
      child: Consumer<ThemePattern<C>>(
        builder: (context, theme, child) {
          return MultiProvider(
            providers: [
              Provider<ThemePattern<C>>.value(value: theme),
              Provider<ThemeData>.value(value: theme.themeData),
            ],
            builder: (context, child) => builder(context, theme, child),
          );
        },
      ),
    );
  }
}
