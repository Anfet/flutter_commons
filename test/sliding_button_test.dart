import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

const width = 300.0;
const thumbWidth = 60.0;
const slidingDuration = Duration(milliseconds: 300);

void main() {
  Widget host({
    required ValueNotifier<SlidingValue?> valueNotifier,
    required ValueNotifier<double> percentNotifier,
    required Future<bool> Function() onSuccess,
    double successThreshold = .7,
    SlidingButtonColorBuilder? trackBackgroundColorBuilder,
    SlidingButtonWidgetBuilder? trackSuccessBuilder,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ValueListenableBuilder<SlidingValue?>(
              valueListenable: valueNotifier,
              builder: (context, value, _) {
                return SlidingButton(
                  value: value,
                  thumbWidth: thumbWidth,
                  slidingDuration: slidingDuration,
                  successThreshold: successThreshold,
                  trackBackgroundColorBuilder: trackBackgroundColorBuilder,
                  trackSuccessBuilder: trackSuccessBuilder,
                  onSuccess: onSuccess,
                  thumbBuilder: (context, percent) {
                    percentNotifier.value = percent;
                    return const SizedBox(key: Key('thumb'), width: thumbWidth, height: 44);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('exposes default semantics', (tester) async {
    final valueNotifier = ValueNotifier<SlidingValue?>(null);
    final percentNotifier = ValueNotifier<double>(0.0);

    await tester.pumpWidget(
      host(
        valueNotifier: valueNotifier,
        percentNotifier: percentNotifier,
        onSuccess: () async => true,
      ),
    );

    final semanticsWidget = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Slide button' &&
            widget.properties.hint == 'Slide to confirm' &&
            widget.properties.value == '0%',
      ),
    );
    expect(semanticsWidget.properties.button, isTrue);
    expect(semanticsWidget.properties.enabled, isTrue);
  });

  testWidgets('stops active animation when thumb is pressed', (tester) async {
    final valueNotifier = ValueNotifier<SlidingValue?>(null);
    final percentNotifier = ValueNotifier<double>(0.0);

    await tester.pumpWidget(
      host(
        valueNotifier: valueNotifier,
        percentNotifier: percentNotifier,
        onSuccess: () async => true,
      ),
    );

    valueNotifier.value = const SlidingValue.fixed(value: 1.0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final beforePress = percentNotifier.value;

    final listenerTopLeft = tester.getTopLeft(find.byType(SlidingButton));
    final slideSize = width - thumbWidth;
    final touchX = listenerTopLeft.dx + beforePress * slideSize + 10;
    final touchY = listenerTopLeft.dy + 10;
    final gesture = await tester.startGesture(Offset(touchX, touchY));

    await tester.pump(slidingDuration);
    final afterPress = percentNotifier.value;
    expect(afterPress, closeTo(beforePress, 0.03));
    expect(afterPress, lessThan(1.0));

    await gesture.up();
  });

  testWidgets('onSuccess is not re-entered while previous call is pending', (tester) async {
    final valueNotifier = ValueNotifier<SlidingValue?>(null);
    final percentNotifier = ValueNotifier<double>(0.0);
    final completion = Completer<bool>();
    var successCalls = 0;

    await tester.pumpWidget(
      host(
        valueNotifier: valueNotifier,
        percentNotifier: percentNotifier,
        onSuccess: () async {
          successCalls++;
          return completion.future;
        },
      ),
    );

    valueNotifier.value = const SlidingValue.fixed(value: 1.0);
    await tester.pump();
    await tester.pump(slidingDuration + const Duration(milliseconds: 20));
    expect(successCalls, 1);

    // Try to re-trigger while onSuccess is still running.
    valueNotifier.value = const SlidingValue.fixed(value: 0.0);
    await tester.pump(const Duration(milliseconds: 20));
    valueNotifier.value = const SlidingValue.fixed(value: 1.0);
    await tester.pump();

    expect(successCalls, 1);

    completion.complete(true);
    await tester.pumpAndSettle();
  });

  testWidgets('starts from 0, below threshold drag returns to 0', (tester) async {
    final valueNotifier = ValueNotifier<SlidingValue?>(null);
    final percentNotifier = ValueNotifier<double>(0.0);
    var successCalls = 0;

    await tester.pumpWidget(
      host(
        valueNotifier: valueNotifier,
        percentNotifier: percentNotifier,
        onSuccess: () async {
          successCalls++;
          return true;
        },
      ),
    );

    expect(percentNotifier.value, 0.0);

    await _dragThumbToPercent(tester, percentNotifier: percentNotifier, targetPercent: 0.6);
    await tester.pump();
    expect(percentNotifier.value, closeTo(0.6, 0.08));

    await tester.pump(slidingDuration);
    expect(percentNotifier.value, closeTo(0.0, 0.02));
    expect(successCalls, 0);
  });

  testWidgets('above threshold reaches 100, updates UI and calls success once', (tester) async {
    final valueNotifier = ValueNotifier<SlidingValue?>(null);
    final percentNotifier = ValueNotifier<double>(0.0);
    var successCalls = 0;

    await tester.pumpWidget(
      host(
        valueNotifier: valueNotifier,
        percentNotifier: percentNotifier,
        onSuccess: () async {
          successCalls++;
          return true;
        },
        trackBackgroundColorBuilder: (_, percent) => percent >= 1.0 ? Colors.green : Colors.blue,
        trackSuccessBuilder: (_, percent) => percent >= 1.0 ? const Icon(Icons.check, key: Key('success-check')) : const SizedBox(),
      ),
    );

    await _dragThumbToPercent(tester, percentNotifier: percentNotifier, targetPercent: 0.85);
    await tester.pumpAndSettle();

    expect(percentNotifier.value, closeTo(1.0, 0.001));
    expect(successCalls, 1);
    expect(find.byKey(const Key('success-check')), findsOneWidget);

    final track = tester.widget<AnimatedContainer>(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius != null,
      ).first,
    );
    expect((track.decoration as BoxDecoration).color, Colors.green);
  });

  testWidgets('fixed keeps assigned value, progressed resolves to side', (tester) async {
    final valueNotifier = ValueNotifier<SlidingValue?>(null);
    final percentNotifier = ValueNotifier<double>(0.0);

    await tester.pumpWidget(
      host(
        valueNotifier: valueNotifier,
        percentNotifier: percentNotifier,
        onSuccess: () async => true,
      ),
    );

    valueNotifier.value = const SlidingValue.fixed(value: 0.4);
    await tester.pumpAndSettle();
    expect(percentNotifier.value, closeTo(0.4, 0.02));

    valueNotifier.value = const SlidingValue.progressed(value: 0.4);
    await tester.pumpAndSettle();
    expect(percentNotifier.value, closeTo(0.0, 0.02));

    valueNotifier.value = const SlidingValue.progressed(value: 0.8);
    await tester.pumpAndSettle();
    expect(percentNotifier.value, closeTo(1.0, 0.02));
  });

  testWidgets('after success slider stays on true response and returns on false response', (tester) async {
    final valueNotifier = ValueNotifier<SlidingValue?>(null);
    final percentNotifier = ValueNotifier<double>(0.0);
    var shouldSucceed = true;
    var successCalls = 0;

    await tester.pumpWidget(
      host(
        valueNotifier: valueNotifier,
        percentNotifier: percentNotifier,
        onSuccess: () async {
          successCalls++;
          return shouldSucceed;
        },
      ),
    );

    await _dragThumbToPercent(tester, percentNotifier: percentNotifier, targetPercent: 0.9);
    await tester.pumpAndSettle();
    expect(percentNotifier.value, closeTo(1.0, 0.02));
    expect(successCalls, 1);

    valueNotifier.value = const SlidingValue.fixed(value: 0.0);
    await tester.pumpAndSettle();
    expect(percentNotifier.value, closeTo(0.0, 0.02));

    shouldSucceed = false;
    await _dragThumbToPercent(tester, percentNotifier: percentNotifier, targetPercent: 0.9);
    await tester.pumpAndSettle();
    expect(percentNotifier.value, closeTo(0.0, 0.02));
    expect(successCalls, 2);
  });
}

Future<void> _dragThumbToPercent(
  WidgetTester tester, {
  required ValueNotifier<double> percentNotifier,
  required double targetPercent,
}) async {
  final slideSize = width - thumbWidth;
  final listenerTopLeft = tester.getTopLeft(find.byType(SlidingButton));
  final startX = listenerTopLeft.dx + percentNotifier.value * slideSize + 10;
  final startY = listenerTopLeft.dy + 10;
  final clampedTargetPercent = targetPercent.clamp(0.0, 1.0);
  final targetX = listenerTopLeft.dx + clampedTargetPercent * slideSize + 10;

  final gesture = await tester.startGesture(Offset(startX, startY));
  await gesture.moveTo(Offset(targetX, startY));
  await gesture.up();
}
