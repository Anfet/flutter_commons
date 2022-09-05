import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../data/lce.dart';

typedef LceWidgetBuilder<T> = Widget Function(BuildContext context, Lce<T> lce);

class LceBuilder<T> extends StatelessWidget {
  final Lce<T> lce;
  final LceWidgetBuilder<T> builder;
  final LceWidgetBuilder<T>? loadingBuilder;
  final LceWidgetBuilder<T>? errorBuilder;
  final LceWidgetBuilder<T>? idleBuilder;
  final bool idleSameAsBuilder;

  const LceBuilder({
    super.key,
    required this.lce,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.idleBuilder,
    this.idleSameAsBuilder = false,
  });

  @override
  Widget build(BuildContext context) {
    if (lce.isLoading) {
      return Center(
          child: (loadingBuilder ?? defaultLoadingBuilder)?.call(context, lce) ?? const CircularProgressIndicator());
    } else if (lce.hasError) {
      return (errorBuilder ?? defaultErrorBuilder)?.call(context, lce) ?? ErrorWidget(lce.requiredError);
    } else if (lce.hasContent || idleSameAsBuilder) {
      return builder(context, lce);
    }

    return idleBuilder?.call(context, lce) ?? Container();
  }

  static LceWidgetBuilder? defaultErrorBuilder;
  static LceWidgetBuilder? defaultLoadingBuilder;
}
