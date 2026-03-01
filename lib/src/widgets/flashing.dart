import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

final _kDefaultDuration = 500.milliseconds;

/// Temporarily highlights background color when [flash] changes from `false` to `true`.
class Flashing extends StatefulWidget {
  /// Wrapped content.
  final Widget child;

  /// Edge-trigger flag. `false -> true` starts one flash cycle.
  final bool flash;

  /// Optional callback called after one flash cycle completes.
  final VoidCallback? onFlashed;

  /// Highlight color used during flash.
  final Color flashColor;

  /// Resting background color outside flash phase.
  final Color backgroundColor;

  /// Flash animation duration.
  final Duration? duration;

  /// Creates a [Flashing] widget.
  const Flashing({
    super.key,
    required this.child,
    this.flash = false,
    this.onFlashed,
    this.flashColor = Colors.transparent,
    this.backgroundColor = Colors.transparent,
    this.duration,
  });

  @override
  State<Flashing> createState() => _FlashingState();
}

class _FlashingState extends State<Flashing> with MountedCheck {
  late Color background = widget.backgroundColor;
  int _flashRunId = 0;

  Duration get _duration => widget.duration ?? _kDefaultDuration;

  bool get _isFlashingColorVisible => background == widget.flashColor;

  @override
  void initState() {
    super.initState();
    if (widget.flash) {
      scheduleOnNextFrame(_runFlash);
    }
  }

  @override
  void didUpdateWidget(covariant Flashing oldWidget) {
    if (!oldWidget.flash && widget.flash) {
      _runFlash();
    } else if (!_isFlashingColorVisible && oldWidget.backgroundColor != widget.backgroundColor) {
      background = widget.backgroundColor;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      color: background,
      child: widget.child,
    );
  }

  Future<void> _runFlash() async {
    final runId = ++_flashRunId;
    background = widget.flashColor;
    markNeedsRebuild();

    await _duration.future;

    if (!mounted || runId != _flashRunId) {
      return;
    }

    background = widget.backgroundColor;
    markNeedsRebuild();
    widget.onFlashed?.call();
  }
}
