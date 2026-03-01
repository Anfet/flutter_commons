import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const flashDuration = Duration(milliseconds: 120);
  const flashColor = Colors.red;
  const backgroundColor = Colors.transparent;
  const childKey = Key('flash-child');

  Widget appFor({
    required ValueNotifier<bool> flashNotifier,
    required VoidCallback onFlashed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: flashNotifier,
          builder: (context, flash, _) {
            return Flashing(
              flash: flash,
              onFlashed: onFlashed,
              duration: flashDuration,
              flashColor: flashColor,
              backgroundColor: backgroundColor,
              child: const SizedBox(key: childKey, width: 20, height: 20),
            );
          },
        ),
      ),
    );
  }

  testWidgets('starts flash from init when flash=true', (tester) async {
    final flashNotifier = ValueNotifier<bool>(true);
    var flashedCount = 0;
    await tester.pumpWidget(appFor(
      flashNotifier: flashNotifier,
      onFlashed: () => flashedCount++,
    ));

    await tester.pump();
    expect(_containerColor(tester), flashColor);

    await tester.pump(flashDuration);
    expect(_containerColor(tester), backgroundColor);
    expect(flashedCount, 1);
  });

  testWidgets('runs only on false->true edge', (tester) async {
    final flashNotifier = ValueNotifier<bool>(false);
    var flashedCount = 0;
    await tester.pumpWidget(appFor(
      flashNotifier: flashNotifier,
      onFlashed: () => flashedCount++,
    ));

    expect(_containerColor(tester), backgroundColor);

    flashNotifier.value = true;
    await tester.pump();
    expect(_containerColor(tester), flashColor);

    await tester.pump(flashDuration);
    expect(_containerColor(tester), backgroundColor);
    expect(flashedCount, 1);

    // Keep true -> no new flash should start.
    flashNotifier.value = true;
    await tester.pump();
    await tester.pump(flashDuration);
    expect(flashedCount, 1);
  });
}

Color? _containerColor(WidgetTester tester) {
  final decoration = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration;
  return (decoration as BoxDecoration?)?.color;
}
