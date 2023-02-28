import 'package:flutter/material.dart';
import 'package:siberian_core/siberian_core.dart';

class LocalizationBuilder<D, P> extends StatelessWidget {
  final Translator<D, P> translator;
  final Widget child;

  const LocalizationBuilder({
    Key? key,
    required this.child,
    required this.translator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: translator,
      builder: (context, value, child) => child!,
      child: child,
    );
  }
}
