import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpWatermark(WidgetTester tester, Widget watermark, {VoidCallback? onTap}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: const ColorScheme.light(onSurface: Color(0xFF123456))),
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque),
            ),
            Positioned.fill(child: watermark),
          ],
        ),
      ),
    );
  }

  Text labelOf(WidgetTester tester) => tester.widget<Text>(find.byType(Text));

  testWidgets('WorkInProgressWatermark uses the original look by default', (tester) async {
    await pumpWatermark(tester, const WorkInProgressWatermark());

    final label = labelOf(tester);
    expect(label.data, 'WORK IN PROGRESS');
    expect(label.style?.fontSize, 64);
    expect(label.style?.fontWeight, FontWeight.w800);
    expect(label.style?.height, 1);
    expect(label.style?.color, const Color(0xFF123456));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.12);
    expect(tester.widget<Transform>(find.byType(Transform).last).transform, Matrix4.rotationZ(-0.12));
  });

  testWidgets('WorkInProgressWatermark applies its properties and lets style win over them', (tester) async {
    await pumpWatermark(
      tester,
      const WorkInProgressWatermark(
        text: 'WIP',
        color: Color(0xFFFF0000),
        fontSize: 20,
        fontWeight: FontWeight.w400,
        opacity: 0.5,
        angle: math.pi / 4,
        style: TextStyle(fontSize: 30, letterSpacing: 2),
      ),
    );

    final label = labelOf(tester);
    expect(label.data, 'WIP');
    expect(label.style?.color, const Color(0xFFFF0000));
    expect(label.style?.fontSize, 30);
    expect(label.style?.fontWeight, FontWeight.w400);
    expect(label.style?.letterSpacing, 2);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
  });

  testWidgets('WorkInProgressWatermark passes touches through unless ignorePointer is false', (tester) async {
    var taps = 0;
    await pumpWatermark(tester, const WorkInProgressWatermark(), onTap: () => taps++);
    await tester.tapAt(tester.getCenter(find.byType(Text)));
    expect(taps, 1);

    await pumpWatermark(tester, const WorkInProgressWatermark(ignorePointer: false), onTap: () => taps++);
    await tester.tapAt(tester.getCenter(find.byType(Text)));
    expect(taps, 1);
  });
}
