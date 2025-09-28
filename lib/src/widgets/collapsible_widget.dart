import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef CollapsibleWidgetBuilder = Widget Function(Animation<double> animation, Widget child);

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

  static const Duration defaultAnimationDuration = Duration(microseconds: 300);

  static CollapsibleWidgetBuilder get defaultAnimationBuilder => (Animation<double> animation, Widget child) => child;
}

class _CollapsibleWidgetState extends State<CollapsibleWidget> with MountedCheck {
  var _animation = .0;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return (widget.builder ?? CollapsibleWidget.defaultAnimationBuilder).call(
          AlwaysStoppedAnimation(_animation),
          _CollapsibleWidget(
            duration: widget.duration ?? CollapsibleWidget.defaultAnimationDuration,
            alignment: widget.alignment ?? Alignment.topCenter,
            curve: widget.curve ?? Curves.linear,
            clipBehavior: widget.clipBehavior ?? Clip.hardEdge,
            builder: widget.builder ?? CollapsibleWidget.defaultAnimationBuilder,
            expanded: widget.expanded,
            onAnimationChanged: (value) {
              _animation = value;
              markNeedsRebuild();
            },
            orientation: widget.orientation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _CollapsibleWidget extends SingleChildRenderObjectWidget {
  final bool expanded;
  final Duration duration;
  final Alignment alignment;
  final CollapsibleWidgetBuilder builder;
  final Clip? clipBehavior;
  final Curve curve;
  final ValueChanged<double> onAnimationChanged;
  final Axis? orientation;

  const _CollapsibleWidget({
    super.child,
    required this.duration,
    required this.expanded,
    required this.alignment,
    required this.builder,
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
      builder: builder,
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
  CollapsibleWidgetBuilder builder;
  Clip clipBehavior;
  Curve curve;
  Axis? orientation;

  _RenderCollapsibleWidget({
    super.textDirection,
    required bool expanded,
    required Duration duration,
    super.alignment,
    required this.builder,
    Clip? clipBehavior,
    required this.curve,
    required this.onAnimationChanged,
    this.orientation,
  })  : _duration = duration,
        _expanded = expanded,
        clipBehavior = clipBehavior ?? Clip.hardEdge;

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
    _duration = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  Timer? timer;
  double animationPosition = 0.0;
  DateTime timestamp = DateTime(0);
  final SizeTween sizeTween = SizeTween(begin: Size.zero, end: Size.zero);
  late final CurveTween curveTween = CurveTween(curve: curve);
  bool hasVisualOverflow = false;
  Size childSize = Size.zero;
  Size targetSize = Size.zero;
  bool requireResize = false;

  Size get _animatedSize {
    var result = sizeTween.transform(curveTween.transform(animationPosition)) ?? Size.zero;
    if (result == Size.zero) {
      return result;
    }

    return switch (orientation) {
      Axis.horizontal => Size(result.width, targetSize.height),
      Axis.vertical => Size(targetSize.width, result.height),
      _ => result,
    };
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
    super.detach();
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
      clipBehavior: clipBehavior,
      oldLayer: _clipRectLayer.layer,
    );
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  void _restartAnimation() {
    requireResize = false;
    animationPosition = 0.0;
    timestamp = DateTime.now();
    timer?.cancel();
    timer = Timer.periodic(30.milliseconds, recalculate);
  }

  void recalculate(Timer timer) {
    var elapsedMsec = DateTime.now().difference(timestamp).inMilliseconds;

    var travelledPercentage = (elapsedMsec / _duration.inMilliseconds);
    animationPosition = travelledPercentage.clamp(0.0, 1.0);
    // warn('tick; elapsed=${elapsedMsec}; position=${animationPosition.toStringAsFixed(2)};');
    if (animationPosition == 0.0 || animationPosition == 1.0) {
      timer.cancel();
    }

    var widthAp = _animatedSize.width / max(sizeTween.end!.width, sizeTween.begin!.width);
    var heightAp = _animatedSize.height / max(sizeTween.end!.height, sizeTween.begin!.height);
    var ap = switch (orientation) {
      Axis.horizontal => widthAp,
      Axis.vertical => heightAp,
      _ => max(widthAp, heightAp),
    }
        .clamp(0.0, 1.0);
    onAnimationChanged(ap);
    markNeedsLayout();
  }
}
