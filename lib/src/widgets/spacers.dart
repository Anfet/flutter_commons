import 'package:flutter/widgets.dart';

/// Returns an empty `SizedBox`.
@pragma("vm:prefer-inline")
//ignore: non_constant_identifier_names
Widget EmptyBox() => const SizedBox();

/// Vertical spacer with optional color and margin.
class VSpacer extends StatelessWidget {
  /// Spacer height.
  final double height;

  /// Optional color used to draw the spacer line.
  final Color? color;

  /// Outer margin around the spacer.
  final EdgeInsets padding;

  @override
  /// Builds a vertical spacer box.
  Widget build(BuildContext context) => Container(height: height, width: 1, color: color, margin: padding);

  /// Creates a vertical spacer.
  const VSpacer(this.height, {super.key, this.color, this.padding = EdgeInsets.zero});
}

/// Horizontal spacer with optional color and margin.
class HSpacer extends StatelessWidget {
  /// Spacer width.
  final double width;

  /// Optional color used to draw the spacer line.
  final Color? color;

  /// Outer margin around the spacer.
  final EdgeInsets padding;

  @override
  /// Builds a horizontal spacer box.
  Widget build(BuildContext context) => Container(width: width, height: 1, color: color, margin: padding);

  /// Creates a horizontal spacer.
  const HSpacer(this.width, {super.key, this.color, this.padding = EdgeInsets.zero});
}

/// Spacer that matches top or bottom safe-area inset.
class NavbarSpacer extends StatelessWidget {
  final _NavbarPosition _position;

  /// Creates a spacer equal to bottom safe-area padding.
  const NavbarSpacer.bottom({super.key}) : _position = _NavbarPosition.bottom;

  /// Creates a spacer equal to top safe-area padding.
  const NavbarSpacer.top({super.key}) : _position = _NavbarPosition.top;

  @override
  /// Builds a safe-area-based vertical spacer.
  Widget build(BuildContext context) {
    return VSpacer(switch (_position) {
      _NavbarPosition.top => MediaQuery.of(context).padding.top,
      _NavbarPosition.bottom => MediaQuery.of(context).padding.bottom,
    });
  }
}

enum _NavbarPosition { top, bottom }

/// Wraps a regular [child] widget into a sliver.
class SliverBox extends StatelessWidget {
  /// Sliver child.
  final Widget? child;

  /// Optional padding applied around [child].
  final EdgeInsets? padding;

  /// Creates a sliver box adapter with optional [padding].
  const SliverBox({
    super.key,
    this.child,
    this.padding,
  });

  @override
  /// Builds a [SliverToBoxAdapter] for [child].
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

/// Sliver that adds empty space along the chosen axis.
class SliverSpacer extends StatelessWidget {
  /// Spacer orientation.
  final Axis orientation;

  /// Spacer size in logical pixels.
  final double dimension;

  /// Creates a vertical sliver spacer.
  const SliverSpacer.v(this.dimension, {super.key}) : orientation = Axis.vertical;

  /// Creates a horizontal sliver spacer.
  const SliverSpacer.h(this.dimension, {super.key}) : orientation = Axis.horizontal;

  @override
  /// Builds a [SliverPadding]-based spacer.
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.only(
        top: orientation == Axis.vertical ? dimension : 0.0,
        left: orientation == Axis.horizontal ? dimension : 0.0,
      ),
    );
  }
}
