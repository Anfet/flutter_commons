// ignore: unused_element

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef SlidingButtonWidgetBuilder = Widget Function(BuildContext context, double percent);
typedef SlidingButtonColorBuilder = Color Function(BuildContext context, double percent);

class SlidingButton extends StatefulWidget {
  static const kSlidingButtonDefaultHeight = 44.0;

  static final kDefaultAnimationDuration = 300.milliseconds;

  static const kDefaulThumbElevation = 4.0;

  ///цвет общей полоски драга
  final SlidingButtonColorBuilder? trackBackgroundColorBuilder;

  ///цвет кнопки для драга
  final SlidingButtonColorBuilder? thumbBackgroundColorBuilder;

  ///билдер для виджета в кнопке драга
  final SlidingButtonWidgetBuilder thumbBuilder;

  ///длина кнопки для драга
  final double thumbWidth;

  ///билдер для виджета по центру
  final SlidingButtonWidgetBuilder? trackContentBuilder;

  ///билдер для виджета с правой строны, обычно иконка
  final SlidingButtonWidgetBuilder? trackSuccessBuilder;

  ///виджет поверх общей кнопки
  final SlidingButtonWidgetBuilder? overlayBuilder;

  final double height;

  ///процент драга после которого аниматор будет тянуть результат к успеху, иначе, к нулю
  final double successThreshold;

  ///функция вызывается когда тумба достигает value = 1.0.
  ///Может быть вызвана только 1 раз при прогрессе более чем [successThreshold].
  final AsyncValueGetter<bool> onSuccess;

  ///длительность анимации кнопки.
  ///по умолчанию [kDefaultAnimationDuration] или 300 msec
  final Duration? slidingDuration;

  ///новое значение для слайдера. см [SlidingValue]
  ///для [SlidingValue.fixed] - значение устанавливается и не анимируется. Можно использовать для ручного управления
  ///для [SlidingValue.progressed] - значение анимируется дальше после установки до 0.0 или 1.0 в зависимости от [successThreshold]
  final SlidingValue? value;

  final double? thumbElevation;

  final bool enabled;
  final bool isInteractable;

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
  });

  @override
  State<SlidingButton> createState() => _SlidingButtonState();
}

class _SlidingButtonState extends State<SlidingButton> with MountedCheck, Logging, SingleTickerProviderStateMixin {
  var isTapped = false;
  var isSliding = false;
  var hasSlidedToComplete = false;
  var isCompleted = false;
  late double slideSize = 0.0;
  Offset tapOffset = Offset.zero;
  late Duration slidingDuration;
  double _value = 0.0;

  double get value => _value;

  set value(double v) {
    _value = v;
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

    if (widget.value != null) {
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
          slideSize = constraints.maxWidth - widget.thumbWidth;
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (details) {
              if (!widget.enabled || isSliding || !widget.isInteractable) {
                return;
              }

              isTapped = details.localPosition.dx.between(thumbWidth.requireFrom, thumbWidth.requireTill);
              tapOffset = Offset(thumbWidth.requireFrom - details.localPosition.dx, widget.height - details.localPosition.dy);
            },
            onPointerUp: (details) {
              if (!widget.enabled || isSliding || !widget.isInteractable) {
                return;
              }
              isTapped = false;
              _runAnimations();
            },
            onPointerMove: (details) {
              if (!widget.enabled || !isTapped || !widget.isInteractable) {
                return;
              }

              var actualPercent = (details.localPosition.dx + tapOffset.dx) / slideSize;

              value = actualPercent.clamp(0.0, 1.0);
              markNeedsRebuild();
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: 300.milliseconds,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: (widget.trackBackgroundColorBuilder ?? kDefaultTrackBackgrounColorBuilder).call(context, value),
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
                    color: (widget.thumbBackgroundColorBuilder ?? kDefaultThumbBackgrounColorBuilder).call(context, value),
                    elevation: widget.thumbElevation ?? SlidingButton.kDefaulThumbElevation,
                    child: AnimatedSwitcher(
                      duration: 300.milliseconds,
                      child: widget.thumbBuilder(context, value),
                    ),
                  ),
                ),
                if (widget.overlayBuilder != null) Positioned.fill(child: require(widget.overlayBuilder).call(context, value)),
              ],
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
      return slidingController.forward().orCancel;
    }
  }

  Future runAnimationToStart() async {
    if (value > 0.0) {
      _animationTween = Tween<double>(begin: value, end: 0.0);
      slidingController.reset();
      slidingController.duration = (slidingDuration.inMilliseconds * ((value - 0.0).abs())).truncate().milliseconds;
      return slidingController.forward().orCancel;
    }
  }

  Future _runAnimations() {
    return value > widget.successThreshold ? runAnimationToSuccess() : runAnimationToStart();
  }

  Future animateTo(double value, {bool animateToSides = false}) async {
    _animationTween = Tween<double>(begin: this.value, end: value);
    slidingController.reset();
    var msecs = (slidingDuration.inMilliseconds * (this.value - value).abs()).round();
    var partialDuration = msecs.milliseconds;
    slidingController.duration = partialDuration;
    await slidingController.forward().orCancel;
    if (animateToSides) {
      _runAnimations();
    }
  }

  static SlidingButtonColorBuilder kDefaultTrackBackgrounColorBuilder = (context, percent) {
    return Theme.of(context).colorScheme.primary.withOpacity(.5);
  };

  static SlidingButtonColorBuilder kDefaultThumbBackgrounColorBuilder = (context, percent) {
    return Theme.of(context).colorScheme.primary;
  };

  Future runSuccess() async {
    warn('runSuccess');
    var success = await widget.onSuccess();
    if (!success) {
      await runAnimationToStart();
    }
  }
}

class SlidingValue {
  final double value;
  final bool runAnimations;

  const SlidingValue.fixed({
    required this.value,
  }) : runAnimations = false;

  const SlidingValue.progressed({
    required this.value,
  }) : runAnimations = true;

  const SlidingValue.zero()
      : runAnimations = false,
        value = 0.0;

  const SlidingValue.custom({
    required this.value,
    required this.runAnimations,
  });

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

  static SlidingButtonWidgetBuilder loadingOverlayBuilder = (context, _) {
    return const Center(child: CupertinoActivityIndicator());
  };
}
