import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

final _KDefaultDuration = 500.milliseconds;

class Flashing extends StatefulWidget {
  final Widget child;
  final ShotReaction? flashReaction;
  final Color? flashColor;
  final Color? backgroundColor;
  final Duration? duration;

  const Flashing({
    super.key,
    required this.child,
    this.flashReaction,
    this.flashColor,
    this.backgroundColor,
    this.duration,
  });

  @override
  State<Flashing> createState() => _FlashingState();
}

class _FlashingState extends State<Flashing> with MountedCheck {
  late Color background = widget.backgroundColor ?? Colors.transparent;

  @override
  void didUpdateWidget(covariant Flashing oldWidget) {
    widget.flashReaction?.consume(flash);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration ?? _KDefaultDuration,
      color: background,
      child: widget.child,
    );
  }

  Future flash(value) async {
    if (!mounted) {
      return;
    }
    background = widget.flashColor ?? Theme.of(context).elevatedButtonTheme.style?.overlayColor?.resolve({}) ?? Colors.transparent;
    markNeedsRebuild();
    await (widget.duration ?? _KDefaultDuration).future;
    background = widget.backgroundColor ?? Colors.transparent;
    markNeedsRebuild();
  }
}
