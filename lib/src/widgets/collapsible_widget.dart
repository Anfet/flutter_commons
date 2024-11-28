import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_commons/flutter_commons.dart';

class CollapsibleWidget extends StatefulWidget {
  final Widget child;
  final bool expanded;
  final ValueSetter<bool>? onCollapseChanged;
  final Duration duration;
  final Alignment alignment;
  final Widget Function(BuildContext context, Animation<double> animation, Widget child) builder;

  const CollapsibleWidget({
    super.key,
    required this.child,
    required this.duration,
    this.expanded = false,
    this.onCollapseChanged,
    this.alignment = Alignment.topCenter,
    this.builder = defaultAnimationBuilder,
  });

  @override
  State<CollapsibleWidget> createState() => _CollapsibleWidgetState();

  static Widget defaultAnimationBuilder(BuildContext context, Animation<double> animation, Widget child) => child;
}

class _CollapsibleWidgetState extends State<CollapsibleWidget> with MountedCheck, Logging {
  late bool expanded = widget.expanded;
  bool requireExpand = false;
  bool requireCollapse = false;

  double? targetSize;

  double get rTargetSize => targetSize ?? 0;

  double? actualSize;

  double get rActualSize => actualSize ?? 0;

  double? fixedSize;

  double get rFixedSize => fixedSize ?? 0;

  double childSize = 0;

  double get visiblePercentage => rFixedSize == 0 ? 0 : rActualSize / rFixedSize;

  bool requireAdjust = false;

  Timer? timer;
  DateTime timestamp = DateTime(0);

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CollapsibleWidget oldWidget) {
    if (widget.expanded != oldWidget.expanded) {
      requireExpand = widget.expanded;
      requireCollapse = !requireExpand;
      requireAdjust = true;
    }

    if (oldWidget.child.runtimeType != widget.child.runtimeType || oldWidget.child.key != widget.child.key) {
      requireAdjust = true;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    var visiblePosition = (rActualSize / max(rFixedSize, rTargetSize)).clamp(0.0, 1.0);
    // warn('visiblePosition=$visiblePosition');
    return _CollapsibleRenderObject(
      key: UniqueKey(),
      state: this,
      child: widget.builder(context, AlwaysStoppedAnimation<double>(visiblePosition), widget.child),
    );
  }

  Size onChildSizeChanged(Size childDrySize) {
    childSize = childDrySize.height;
    // warn('childSize = $childSize');
    if (fixedSize == null) {
      targetSize = expanded ? childSize : 0.0;
      actualSize = targetSize;
    }
    fixedSize ??= childDrySize.height;
    if (requireAdjust) {
      requireAdjust = false;
      readjust();
    }

    var visibleSize = rFixedSize * visiblePercentage;
    // warn('visibleSize = $visibleSize');
    var size = Size(childDrySize.width, visibleSize);
    return size;
  }

  void onTick(_) {
    var elapsedMsec = DateTime.now().difference(timestamp).inMilliseconds;

    timestamp = DateTime.now();

    var maxSize = max(rTargetSize, rFixedSize);
    var travelledPx = (elapsedMsec / widget.duration.inMilliseconds) * maxSize;
    var travelledMultilier = rTargetSize > rFixedSize ? 1 : -1;
    travelledPx *= travelledMultilier;

    actualSize = clampDouble(rActualSize + travelledPx, 0, maxSize);
    fixedSize = max(rActualSize, rFixedSize);

    var actualReachedBounds = rActualSize <= 0.0 || rActualSize >= maxSize;
    var actualReachedTarget = travelledMultilier > 0 ? rActualSize > rTargetSize : rActualSize < rTargetSize;

    if (actualReachedBounds || actualReachedTarget) {
      expanded = requireExpand;
      requireCollapse = false;
      requireExpand = false;
      fixedSize = targetSize;
      actualSize = targetSize;
      // warn('ticker stopped; actual = $rActualSize');
      widget.onCollapseChanged?.call(expanded);

      timer?.cancel();
    }

    markNeedsRebuild();
  }

  void readjust() {
    // ticker?.dispose();
    timer?.cancel();

    if (childSize != fixedSize) {
      targetSize = childSize;
    }

    if (requireExpand) {
      requireExpand = false;
      targetSize = childSize;
    }

    if (requireCollapse) {
      requireCollapse = false;
      targetSize = 0.0;
    }

    if (targetSize == actualSize) {
      return;
    }

    // warn('ticker start; from=$actualSize; to=$targetSize');
    timestamp = DateTime.now();
    timer = Timer.periodic(30.milliseconds, onTick);
  }
}

class _CollapsibleRenderObject extends SingleChildRenderObjectWidget {
  final _CollapsibleWidgetState state;

  _CollapsibleRenderObject({
    super.key,
    required super.child,
    required this.state,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCollapsibleObject(state: state);
}

class _RenderCollapsibleObject extends RenderProxyBox {
  final _CollapsibleWidgetState state;

  _RenderCollapsibleObject({
    RenderBox? child,
    required this.state,
  }) : super(child);

  @override
  void performLayout() {
    var selfConstraints = constraints;
    var childDrySize = child?.computeDryLayout(constraints) ?? computeSizeForNoChild(constraints);
    size = state.onChildSizeChanged(childDrySize);
    // var childDryHeight = child?.computeDryLayout(constraints).height;
    // var measured = (child?..layout(selfConstraints, parentUsesSize: true))?.size ?? computeSizeForNoChild(constraints);
    // print('childRealHeight = ${measured.height}');
    // size = Size(measured.width, measured.height * heightLimit);
    selfConstraints = selfConstraints.copyWith(maxHeight: size.height);
    child?..layout(selfConstraints, parentUsesSize: true);

    // print('performing layout; size  = $size; height limit = ${heightLimit}');
  }
}
