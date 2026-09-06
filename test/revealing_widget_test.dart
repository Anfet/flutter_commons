import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const initialDuration = Duration(milliseconds: 120);
  const updatedDuration = Duration(milliseconds: 240);

  Widget buildWidget({
    required AppearingController controller,
    required Duration duration,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RevealingWidget(
        duration: duration,
        controller: controller,
        child: const Text('revealed content'),
      ),
    );
  }

  testWidgets('animates on mount and restarts through its controller', (
    tester,
  ) async {
    final controller = AppearingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildWidget(controller: controller, duration: initialDuration),
    );

    expect(find.text('revealed content'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);

    final initialFrames = await tester.pumpAndSettle();
    expect(initialFrames, greaterThan(1));
    expect(tester.hasRunningAnimations, isFalse);

    controller.restartAnimation();
    expect(tester.hasRunningAnimations, isTrue);

    final restartFrames = await tester.pumpAndSettle();
    expect(restartFrames, greaterThan(1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('updates duration and transfers the external controller listener', (
    tester,
  ) async {
    final oldController = AppearingController();
    final newController = AppearingController();
    addTearDown(oldController.dispose);
    addTearDown(newController.dispose);

    await tester.pumpWidget(
      buildWidget(controller: oldController, duration: initialDuration),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      buildWidget(controller: newController, duration: updatedDuration),
    );
    expect(tester.hasRunningAnimations, isFalse);

    oldController.restartAnimation();
    expect(tester.hasRunningAnimations, isFalse);

    newController.restartAnimation();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump();
    await tester.pump(initialDuration);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('detaches its external controller when disposed', (tester) async {
    final controller = AppearingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildWidget(controller: controller, duration: initialDuration),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());

    expect(controller.restartAnimation, returnsNormally);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
