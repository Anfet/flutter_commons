// ignore: unused_element

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef SlidingButtonWidgetBuilder = Widget Function(BuildContext context, double percent);
typedef SlidingButtonColorBuilder = Color Function(BuildContext context, double percent);

/// A "slide to confirm" control with async completion callback.
///
/// Drag the thumb from left to right. When released:
/// - below [successThreshold] it animates back to start
/// - above [successThreshold] it animates to end and calls [onSuccess]
class SlidingButton extends StatefulWidget {
  /// Default widget height.
  static const kSlidingButtonDefaultHeight = 44.0;

  /// Default duration for slider animations.
  static final kDefaultAnimationDuration = 300.milliseconds;

  /// Default thumb elevation.
  static const kDefaultThumbElevation = 4.0;

  @Deprecated('Use kDefaultThumbElevation')
  static const kDefaulThumbElevation = kDefaultThumbElevation;

  static SlidingButtonColorBuilder defaultTrackBackgroundColorBuilder = (context, percent) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: .5);
  };

  static SlidingButtonColorBuilder defaultThumbBackgroundColorBuilder = (context, percent) {
    return Theme.of(context).colorScheme.primary;
  };

  @Deprecated('Use defaultTrackBackgroundColorBuilder')
  static SlidingButtonColorBuilder get kDefaultTrackBackgrounColorBuilder => defaultTrackBackgroundColorBuilder;

  @Deprecated('Use defaultTrackBackgroundColorBuilder')
  static set kDefaultTrackBackgrounColorBuilder(SlidingButtonColorBuilder value) => defaultTrackBackgroundColorBuilder = value;

  @Deprecated('Use defaultThumbBackgroundColorBuilder')
  static SlidingButtonColorBuilder get kDefaultThumbBackgrounColorBuilder => defaultThumbBackgroundColorBuilder;

  @Deprecated('Use defaultThumbBackgroundColorBuilder')
  static set kDefaultThumbBackgrounColorBuilder(SlidingButtonColorBuilder value) => defaultThumbBackgroundColorBuilder = value;

  /// Builds track background color from current progress (`0..1`).
  final SlidingButtonColorBuilder? trackBackgroundColorBuilder;

  /// Builds thumb background color from current progress (`0..1`).
  final SlidingButtonColorBuilder? thumbBackgroundColorBuilder;

  /// Builds thumb content from current progress (`0..1`).
  final SlidingButtonWidgetBuilder thumbBuilder;

  /// Thumb width in logical pixels.
  final double thumbWidth;

  /// Optional builder for centered track content.
  final SlidingButtonWidgetBuilder? trackContentBuilder;

  /// Optional builder for right-side success content.
  final SlidingButtonWidgetBuilder? trackSuccessBuilder;

  /// Optional builder for full overlay above the control.
  final SlidingButtonWidgetBuilder? overlayBuilder;

  /// Widget height.
  final double height;

  /// Completion threshold (`0..1`).
  final double successThreshold;

  /// Called when progress reaches `1.0`.
  ///
  /// Return `true` to keep slider at end. Return `false` to animate back to start.
  final AsyncValueGetter<bool> onSuccess;

  /// Optional animation duration for all internal slider animations.
  final Duration? slidingDuration;

  /// External control value. See [SlidingValue].
  final SlidingValue? value;

  /// Optional custom thumb elevation.
  final double? thumbElevation;

  /// Enables/disables the control.
  final bool enabled;

  /// Enables/disables user drag interactions.
  final bool isInteractable;

  /// Optional semantics label.
  final String? semanticLabel;

  /// Optional semantics hint.
  final String? semanticHint;

  /// Creates a [SlidingButton].
  const SlidingButton({
    super.key,
    this.trackBackgroundColorBuilder,
    this.thumbBackgroundColorBuilder,
    required this.thumbBuilder,
    required this.thumbWidth,
    this.overlayBuilder,
    this.trackContentBuilder,
    this.trackSuccessBuilder,
    this.height = kSlidingButtonDefaultHeight,
    this.successThreshold = .7,
    required this.onSuccess,
    this.value,
    this.slidingDuration,
    this.thumbElevation,
    this.enabled = true,
    this.isInteractable = true,
    this.semanticLabel,
    this.semanticHint,
  }) : assert(successThreshold >= 0.0 && successThreshold <= 1.0);

  @override
  State<SlidingButton> createState() => _SlidingButtonState();
}

class _SlidingButtonState extends State<SlidingButton> with MountedCheck, SingleTickerProviderStateMixin {
  var isTapped = false;
  var _isRunningSuccess = false;
  late double slideSize = 0.0;
  Offset tapOffset = Offset.zero;
  late Duration slidingDuration;
  double _value = 0.0;

  double get value => _value;

  set value(double v) {
    _value = v.clamp(0.0, 1.0);
    if (value < widget.successThreshold) {
      canTriggerSuccess = true;
    } else if (canTriggerSuccess && value >= 1.0) {
      canTriggerSuccess = false;
      runSuccess();
    }
  }

  late bool canTriggerSuccess = value < 1.0;

  Range<double> get thumbWidth => Range(
        slideSize * value,
        slideSize * value + widget.thumbWidth,
      );

  late AnimationController slidingController;
  Tween<double>? _animationTween;

  @override
  void initState() {
    slidingDuration = widget.slidingDuration ?? SlidingButton.kDefaultAnimationDuration;
    slidingController = AnimationController(vsync: this, duration: slidingDuration);
    slidingController.addListener(
      () {
        value = _animationTween!.evaluate(require(slidingController));
        markNeedsRebuild();
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    slidingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SlidingButton oldWidget) {
    if (widget.slidingDuration != slidingDuration) {
      slidingDuration = widget.slidingDuration ?? SlidingButton.kDefaultAnimationDuration;
    }

    if (oldWidget.value != widget.value && widget.value != null) {
      animateTo(require(widget.value).value, animateToSides: require(widget.value).runAnimations);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          slideSize = (constraints.maxWidth - widget.thumbWidth).clamp(0.0, double.infinity);
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (details) {
              if (!widget.enabled || !widget.isInteractable || _isRunningSuccess) {
                return;
              }

              final isThumbTapped = details.localPosition.dx.between(thumbWidth.requireFrom, thumbWidth.requireTill);
              if (isThumbTapped && slidingController.isAnimating) {
                slidingController.stop();
              }

              isTapped = isThumbTapped;
              tapOffset = Offset(thumbWidth.requireFrom - details.localPosition.dx, widget.height - details.localPosition.dy);
            },
            onPointerUp: (details) {
              if (!widget.enabled || !widget.isInteractable || _isRunningSuccess) {
                return;
              }
              isTapped = false;
              _runAnimations();
            },
            onPointerMove: (details) {
              if (!widget.enabled || !isTapped || !widget.isInteractable || slideSize <= 0.0 || _isRunningSuccess) {
                return;
              }

              var actualPercent = (details.localPosition.dx + tapOffset.dx) / slideSize;

              value = actualPercent.clamp(0.0, 1.0);
              markNeedsRebuild();
            },
            child: Semantics(
              container: true,
              button: true,
              enabled: widget.enabled && widget.isInteractable && !_isRunningSuccess,
              label: widget.semanticLabel ?? 'Slide button',
              hint: widget.semanticHint ?? 'Slide to confirm',
              value: '${(value * 100).round()}%',
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: 300.milliseconds,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: (widget.trackBackgroundColorBuilder ?? SlidingButton.defaultTrackBackgroundColorBuilder).call(context, value),
                      ),
                    ),
                  ),
                  if (widget.trackContentBuilder != null)
                    Positioned.fill(
                      child: Center(child: widget.trackContentBuilder?.call(context, value)),
                    ),
                  if (widget.trackSuccessBuilder != null)
                    Positioned(top: 0, bottom: 0, right: 0, child: require(widget.trackSuccessBuilder?.call(context, value))),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    width: widget.thumbWidth + value * slideSize,
                    child: PhysicalModel(
                      borderRadius: BorderRadius.circular(12),
                      color: (widget.thumbBackgroundColorBuilder ?? SlidingButton.defaultThumbBackgroundColorBuilder).call(context, value),
                      elevation: widget.thumbElevation ?? SlidingButton.kDefaultThumbElevation,
                      child: AnimatedSwitcher(
                        duration: 300.milliseconds,
                        child: widget.thumbBuilder(context, value),
                      ),
                    ),
                  ),
                  if (widget.overlayBuilder != null) Positioned.fill(child: require(widget.overlayBuilder).call(context, value)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future runAnimationToSuccess() async {
    if (value < 1.0) {
      _animationTween = Tween<double>(begin: value, end: 1.0);
      slidingController.reset();
      slidingController.duration = (slidingDuration.inMilliseconds * ((value - 1.0).abs())).truncate().milliseconds;
      try {
        await slidingController.forward().orCancel;
      } on TickerCanceled {
        return;
      }
    }
  }

  Future runAnimationToStart() async {
    if (value > 0.0) {
      _animationTween = Tween<double>(begin: value, end: 0.0);
      slidingController.reset();
      slidingController.duration = (slidingDuration.inMilliseconds * ((value - 0.0).abs())).truncate().milliseconds;
      try {
        await slidingController.forward().orCancel;
      } on TickerCanceled {
        return;
      }
    }
  }

  Future _runAnimations() {
    return value > widget.successThreshold ? runAnimationToSuccess() : runAnimationToStart();
  }

  Future animateTo(double value, {bool animateToSides = false}) async {
    final targetValue = value.clamp(0.0, 1.0);
    _animationTween = Tween<double>(begin: this.value, end: targetValue);
    slidingController.reset();
    var msecs = (slidingDuration.inMilliseconds * (this.value - targetValue).abs()).round();
    var partialDuration = msecs.milliseconds;
    slidingController.duration = partialDuration;
    try {
      await slidingController.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    if (animateToSides) {
      _runAnimations();
    }
  }

  Future runSuccess() async {
    if (_isRunningSuccess) {
      return;
    }

    _isRunningSuccess = true;
    try {
      var success = await widget.onSuccess();
      if (!success) {
        await runAnimationToStart();
      }
    } finally {
      _isRunningSuccess = false;
    }
  }
}

/// Public class SlidingValue.
class SlidingValue {
  /// Explicit slider value (`0..1`).
  final double value;

  /// Whether to animate to nearest side after applying [value].
  final bool runAnimations;

  /// Applies [value] without side animation.
  const SlidingValue.fixed({
    required this.value,
  })  : runAnimations = false,
        assert(value >= 0.0 && value <= 1.0);

  /// Applies [value] and then animates to nearest side.
  const SlidingValue.progressed({
    required this.value,
  })  : runAnimations = true,
        assert(value >= 0.0 && value <= 1.0);

  /// Convenience zero value (`0.0`) without side animation.
  const SlidingValue.zero()
      : runAnimations = false,
        value = 0.0;

  /// Fully custom value and side-animation behavior.
  const SlidingValue.custom({
    required this.value,
    required this.runAnimations,
  }) : assert(value >= 0.0 && value <= 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlidingValue && runtimeType == other.runtimeType && value == other.value && runAnimations == other.runAnimations;

  @override
  int get hashCode => value.hashCode ^ runAnimations.hashCode;

  @override
  String toString() {
    return 'SlidingValue{value: $value, runAnimations: $runAnimations}';
  }

  /// Overlay builder with a loading indicator.
  static SlidingButtonWidgetBuilder loadingOverlayBuilder = (context, _) {
    return const Center(child: CupertinoActivityIndicator());
  };
}
