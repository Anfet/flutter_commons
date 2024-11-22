import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_commons/flutter_commons.dart';

class CollapsibleWidget extends StatefulWidget {
  final Widget child;
  final bool isCollapsed;
  final ValueSetter<bool>? onCollapseChanged;
  final Duration duration;
  final Alignment alignment;
  final Widget Function(BuildContext context, Animation<double> animation, Widget child) builder;

  const CollapsibleWidget({
    super.key,
    required this.child,
    required this.duration,
    this.isCollapsed = false,
    this.onCollapseChanged,
    this.alignment = Alignment.topCenter,
    this.builder = defaultAnimationBuilder,
  });

  @override
  State<CollapsibleWidget> createState() => _CollapsibleWidgetState();

  static Widget defaultAnimationBuilder(BuildContext context, Animation<double> animation, Widget child) => child;
}

class _CollapsibleWidgetState extends State<CollapsibleWidget> with SingleTickerProviderStateMixin, MountedCheck {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool requireMeasure = true;
  Size? measuredSize;

  bool get isFirstAppearance => measuredSize == null;
  late bool requireCollapse;
  bool isCollapsed = false;

  @override
  void initState() {
    isCollapsed = widget.isCollapsed;
    requireCollapse = isCollapsed;
    _controller.addStatusListener(_controllerStatusListener);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CollapsibleWidget oldWidget) {
    if (oldWidget.child.runtimeType != widget.child.runtimeType || oldWidget.child.key != widget.child.key) {
      requireMeasure = true;
    }

    _controller.duration = widget.duration;
    if (widget.isCollapsed != requireCollapse) {
      requireCollapse = widget.isCollapsed;
      _controller.isAnimating
          ? _controller.toggle()
          : requireCollapse
          ? _controller.reverse(from: 1.0)
          : _controller.forward(from: 0.0);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Align(
              alignment: widget.alignment,
              child: isFirstAppearance || requireMeasure
                  ? child!
                  : SizedBox(
                height: _controller.value * measuredSize!.height,
                child: widget.builder(context, _controller, child!),
              ),
            ),
          ],
        );
      },
      child: _CollapsibleRenderObject(
        onSizeMeasured: onSizeMeasured,
        child: widget.child,
      ),
    );
  }

  void onSizeMeasured(Size size) {
    if (requireMeasure) {
      measuredSize = size;
      print('size changed = $size');
      requireMeasure = false;
      scheduleOnNextFrame(
            () {
          _controller.value = isCollapsed ? 0.0 : 1.0;
          markNeedsRebuild();
        },
      );
    }
  }

  void _controllerStatusListener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        return;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        return;
      case AnimationStatus.completed:
        isCollapsed = requireCollapse;
        widget.onCollapseChanged?.call(isCollapsed);
        return;
    }
  }
}

class _CollapsibleRenderObject extends SingleChildRenderObjectWidget {
  final ValueSetter<Size> onSizeMeasured;

  _CollapsibleRenderObject({
    required this.onSizeMeasured,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCollapsibleObject(onSizeMeasured: onSizeMeasured);
}

class _RenderCollapsibleObject extends RenderProxyBox {
  final ValueSetter<Size> onSizeMeasured;

  _RenderCollapsibleObject({
    RenderBox? child,
    required this.onSizeMeasured,
  }) : super(child);

  @override
  void performLayout() {
    size = child != null ? ChildLayoutHelper.layoutChild(child!, constraints) : constraints.smallest;
    onSizeMeasured(size);
  }
}