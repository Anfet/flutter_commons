import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpTile(WidgetTester tester, {VoidCallback? onTap, ScrollController? controller}) {
    return tester.pumpWidget(
      MaterialApp(
        home: ListView(
          controller: controller,
          children: [
            PressScale(
              onTap: onTap,
              scale: 0.5,
              opacity: 0.4,
              child: const SizedBox(key: ValueKey('tile'), width: 100, height: 100),
            ),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
  }

  double scaleOf(WidgetTester tester) => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  double opacityOf(WidgetTester tester) => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

  testWidgets('PressScale shrinks and dims while pressed and restores on release', (tester) async {
    var taps = 0;
    await pumpTile(tester, onTap: () => taps++);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('tile'))));
    await tester.pump();
    expect(scaleOf(tester), 0.5);
    expect(opacityOf(tester), 0.4);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
    expect(opacityOf(tester), 1);
    expect(taps, 1);
  });

  testWidgets('PressScale with null onTap shows no press effect', (tester) async {
    await pumpTile(tester);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('tile'))));
    await tester.pump();
    expect(scaleOf(tester), 1);
    expect(opacityOf(tester), 1);

    await gesture.up();
  });

  testWidgets('PressScale releases the press without a tap when the enclosing scroll takes the drag', (tester) async {
    var taps = 0;
    await pumpTile(tester, onTap: () => taps++);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('tile'))));
    await tester.pump();
    expect(scaleOf(tester), 0.5);

    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(scaleOf(tester), 1);
    expect(taps, 0);
  });
}
