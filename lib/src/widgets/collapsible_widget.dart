import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef CollapsibleWidgetBuilder = Widget Function(Animation<double> animation, Widget child);

/// Public class CollapsibleWidget.
class CollapsibleWidget extends StatefulWidget {
  final Widget child;
  final bool expanded;
  final Duration? duration;
  final Alignment? alignment;
  final CollapsibleWidgetBuilder? builder;
  final Clip? clipBehavior;
  final Curve? curve;
  final Axis? orientation;

  const CollapsibleWidget({
    super.key,
    required this.child,
    this.duration,
    this.expanded = false,
    this.alignment,
    this.clipBehavior,
    this.curve,
    this.builder,
    this.orientation,
  });

  @override
  State<CollapsibleWidget> createState() => _CollapsibleWidgetState();

  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  static CollapsibleWidgetBuilder get defaultAnimationBuilder =>
      (Animation<double> animation, Widget child) => child;
}

class _CollapsibleWidgetState extends State<CollapsibleWidget> with MountedCheck {
  var _animation = .0;

  @override
  Widget build(BuildContext context) {
    return (widget.builder ?? CollapsibleWidget.defaultAnimationBuilder).call(
      AlwaysStoppedAnimation(_animation),
      _CollapsibleWidget(
        duration: widget.duration ?? CollapsibleWidget.defaultAnimationDuration,
        alignment: widget.alignment ?? Alignment.topCenter,
        curve: widget.curve ?? Curves.linear,
        clipBehavior: widget.clipBehavior ?? Clip.hardEdge,
        expanded: widget.expanded,
        onAnimationChanged: (value) {
          _animation = value;
          markNeedsRebuild();
        },
        orientation: widget.orientation,
        child: widget.child,
      ),
    );
  }
}

class _CollapsibleWidget extends SingleChildRenderObjectWidget {
  final bool expanded;
  final Duration duration;
  final Alignment alignment;
  final Clip? clipBehavior;
  final Curve curve;
  final ValueChanged<double> onAnimationChanged;
  final Axis? orientation;

  const _CollapsibleWidget({
    super.child,
    required this.duration,
    required this.expanded,
    required this.alignment,
    required this.curve,
    this.clipBehavior,
    required this.onAnimationChanged,
    this.orientation,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCollapsibleWidget(
      textDirection: Directionality.maybeOf(context),
      curve: curve,
      duration: duration,
      expanded: expanded,
      clipBehavior: clipBehavior,
      alignment: alignment,
      onAnimationChanged: onAnimationChanged,
      orientation: orientation,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCollapsibleWidget renderObject) {
    renderObject
      ..expanded = expanded
      ..alignment = alignment
      ..duration = duration
      ..curve = curve
      ..textDirection = Directionality.maybeOf(context)
      ..clipBehavior = clipBehavior ?? Clip.hardEdge
      ..onAnimationChanged = onAnimationChanged
      ..orientation = orientation;
  }
}

class _RenderCollapsibleWidget extends RenderAligningShiftedBox {
  ValueChanged<double> onAnimationChanged;
  bool _expanded;
  Duration _duration;
  Clip _clipBehavior;
  Curve _curve;
  Axis? _orientation;

  _RenderCollapsibleWidget({
    super.textDirection,
    required bool expanded,
    required Duration duration,
    super.alignment,
    Clip? clipBehavior,
    required Curve curve,
    required this.onAnimationChanged,
    Axis? orientation,
  }) : _duration = duration,
       _expanded = expanded,
       _curve = curve,
       curveTween = CurveTween(curve: curve),
       _clipBehavior = clipBehavior ?? Clip.hardEdge,
       _orientation = orientation;

  set expanded(bool value) {
    if (_expanded != value) {
      _expanded = value;
      // warn('expanded changed to $_expanded');
      requireResize = true;
      markNeedsLayout();
      markNeedsSemanticsUpdate();
    }
  }

  set duration(Duration value) {
    if (_duration != value) {
      _duration = value;
      markNeedsLayout();
      markNeedsSemanticsUpdate();
    }
  }

  set curve(Curve value) {
    if (_curve != value) {
      _curve = value;
      curveTween = CurveTween(curve: value);
      requireResize = true;
      markNeedsLayout();
      markNeedsSemanticsUpdate();
    }
  }

  set clipBehavior(Clip value) {
    if (_clipBehavior != value) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  set orientation(Axis? value) {
    if (_orientation != value) {
      _orientation = value;
      markNeedsLayout();
    }
  }

  Timer? timer;
  double animationPosition = 0.0;
  DateTime timestamp = DateTime(0);
  final SizeTween sizeTween = SizeTween(begin: Size.zero, end: Size.zero);
  CurveTween curveTween;
  bool hasVisualOverflow = false;
  Size childSize = Size.zero;
  Size targetSize = Size.zero;
  bool requireResize = false;

  Size get _animatedSize {
    var result = sizeTween.transform(curveTween.transform(animationPosition)) ?? Size.zero;
    if (result == Size.zero) {
      return result;
    }

    return switch (_orientation) {
      Axis.horizontal => Size(result.width, targetSize.height),
      Axis.vertical => Size(targetSize.width, result.height),
      _ => result,
    };
  }

  double get _animationPercent {
    final widthAp = _sizePercent(_animatedSize.width, sizeTween.end!.width, sizeTween.begin!.width);
    final heightAp = _sizePercent(_animatedSize.height, sizeTween.end!.height, sizeTween.begin!.height);
    return switch (_orientation) {
      Axis.horizontal => widthAp,
      Axis.vertical => heightAp,
      _ => max(widthAp, heightAp),
    }.clamp(0.0, 1.0);
  }

  double _sizePercent(double size, double firstTarget, double secondTarget) {
    final maximum = max(firstTarget, secondTarget);
    if (maximum <= 0.0) {
      return animationPosition.clamp(0.0, 1.0);
    }
    return (size / maximum).clamp(0.0, 1.0);
  }

  @override
  void performLayout() {
    hasVisualOverflow = false;
    final BoxConstraints constraints = this.constraints;
    if (constraints.isTight) {
      // warn('timer cancel; no child');
      timer?.cancel();
      size = sizeTween.begin = sizeTween.end = constraints.smallest;
      child?.layout(constraints);
      return;
    }

    child!.layout(constraints, parentUsesSize: true);
    childSize = child!.size;
    targetSize = _expanded ? childSize : Size.zero;

    if (sizeTween.end != targetSize || requireResize) {
      // warn('child size changed = ${sizeTween.end} > ${targetSize}|${_expanded}');
      sizeTween.begin = _animatedSize;
      sizeTween.end = debugAdoptSize(targetSize);
      _restartAnimation();
    } else {
      _resumeAnimation();
    }

    size = constraints.constrain(_animatedSize);
    alignChild();

    if (size.width < sizeTween.end!.width || size.height < sizeTween.end!.height) {
      hasVisualOverflow = true;
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    markNeedsLayout();
  }

  @override
  void detach() {
    timer?.cancel();
    timer = null;
    super.detach();
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    // warn('compute dry layout');
    if (child == null || constraints.isTight || !_expanded) {
      return constraints.smallest;
    }

    var size = child!.getDryLayout(constraints);
    return constraints.constrain(size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Rect rect = Offset.zero & size;
    _clipRectLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      rect,
      super.paint,
      clipBehavior: _clipBehavior,
      oldLayer: _clipRectLayer.layer,
    );
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  void _restartAnimation() {
    requireResize = false;
    timer?.cancel();
    timer = null;

    if (_duration.inMicroseconds <= 0) {
      animationPosition = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyAnimationChanged();
      });
      return;
    }

    animationPosition = 0.0;
    timestamp = DateTime.now();
    timer = Timer.periodic(30.milliseconds, recalculate);
  }

  void _resumeAnimation() {
    if (timer != null || animationPosition >= 1.0 || sizeTween.begin == sizeTween.end) {
      return;
    }

    if (_duration.inMicroseconds <= 0) {
      animationPosition = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyAnimationChanged();
      });
      return;
    }

    final elapsedMicros = (_duration.inMicroseconds * animationPosition).round();
    timestamp = DateTime.now().subtract(Duration(microseconds: elapsedMicros));
    timer = Timer.periodic(30.milliseconds, recalculate);
  }

  void recalculate(Timer timer) {
    if (!attached) {
      timer.cancel();
      this.timer = null;
      return;
    }
    if (_duration.inMicroseconds <= 0) {
      timer.cancel();
      this.timer = null;
      animationPosition = 1.0;
      markNeedsLayout();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyAnimationChanged();
      });
      return;
    }

    final elapsedMicros = DateTime.now().difference(timestamp).inMicroseconds;

    final travelledPercentage = elapsedMicros / _duration.inMicroseconds;
    animationPosition = travelledPercentage.clamp(0.0, 1.0);
    // warn('tick; elapsed=${elapsedMsec}; position=${animationPosition.toStringAsFixed(2)};');
    if (animationPosition == 0.0 || animationPosition == 1.0) {
      timer.cancel();
      this.timer = null;
    }

    _notifyAnimationChanged();
    markNeedsLayout();
  }

  void _notifyAnimationChanged() {
    if (!attached) {
      return;
    }
    final percent = _animationPercent;
    if (percent.isFinite) {
      onAnimationChanged(percent);
    }
  }
}
