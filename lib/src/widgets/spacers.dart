import 'package:flutter/widgets.dart';

Widget EmptyBox() => const SizedBox();

class VSpacer extends StatelessWidget {
  final double height;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(height: height, width: 1, color: color, margin: padding);

  const VSpacer(this.height, {super.key, this.color, this.padding = EdgeInsets.zero});
}

class HSpacer extends StatelessWidget {
  final double width;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(width: width, height: 1, color: color, margin: padding);

  const HSpacer(this.width, {super.key, this.color, this.padding = EdgeInsets.zero});
}

class NavbarSpacer extends StatelessWidget {
  final _NavbarPosition _position;

  const NavbarSpacer.bottom({super.key}) : _position = _NavbarPosition.bottom;

  const NavbarSpacer.top({super.key}) : _position = _NavbarPosition.top;

  @override
  Widget build(BuildContext context) {
    return VSpacer(switch (_position) {
      _NavbarPosition.top => MediaQuery.of(context).padding.top,
      _NavbarPosition.bottom => MediaQuery.of(context).padding.bottom,
    });
  }
}

enum _NavbarPosition { top, bottom }

class SliverBox extends StatelessWidget {
  final Widget? child;
  final EdgeInsets? padding;

  const SliverBox({
    super.key,
    this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
