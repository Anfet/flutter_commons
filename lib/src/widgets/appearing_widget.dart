import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

class AppearingWidget extends StatefulWidget {
  final Duration? duration;
  final bool show;
  final Alignment alignment;
  final Widget? child;

  const AppearingWidget({
    super.key,
    required this.show,
    required this.alignment,
    this.child,
    this.duration,
  });

  @override
  State<AppearingWidget> createState() => _AppearingWidgetState();
}

class _AppearingWidgetState extends State<AppearingWidget> with MountedCheck {
  late Widget? child = widget.child;
  late bool isShowing = widget.show;

  @override
  void didUpdateWidget(covariant AppearingWidget oldWidget) {
    if (widget.child == null) {
      isShowing = false;
    }

    if (widget.child != null) {
      child = widget.child;
    }

    if (widget.show) {
      isShowing = true;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: widget.duration ?? 300.milliseconds,
      alignment: widget.alignment,
      clipBehavior: Clip.antiAlias,
      child: isShowing
          ? AnimatedOpacity(
              opacity: widget.show ? 1.0 : 0.0,
              duration: widget.duration ?? 300.milliseconds,
              child: child,
              onEnd: () {
                isShowing = widget.show;
                markNeedsRebuild();
              },
            )
          : EmptyBox(),
    );
  }
}
