import 'package:flutter/material.dart';
import 'package:siberian_core/siberian_core.dart';

class LocalizationBuilder<D, P> extends StatelessWidget {
  final Translator<D, P> translator;
  final TransitionBuilder builder;
  final Widget? child;

  const LocalizationBuilder({
    super.key,
    required this.translator,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: translator,
      builder: builder,
      child: child,
    );
  }
}
