import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SlidingWidget invalidates a pending delay when the delay changes', (tester) async {
    Widget build(Duration delay) => Directionality(
      textDirection: TextDirection.ltr,
      child: SlidingWidget(
        orientation: SlidingOrientation.leftToRight,
        duration: const Duration(milliseconds: 100),
        delay: delay,
        child: const SizedBox(width: 20, height: 20),
      ),
    );

    await tester.pumpWidget(build(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(build(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.widget<FractionalTranslation>(find.byType(FractionalTranslation)).translation.dx, -1.0);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<FractionalTranslation>(find.byType(FractionalTranslation)).translation.dx, greaterThan(-1.0));
  });

  testWidgets('CollapsibleWidget reports finite constrained progress for a zero-sized child', (tester) async {
    final progress = <double>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CollapsibleWidget(
          expanded: true,
          duration: Duration.zero,
          builder: (animation, child) {
            progress.add(animation.value);
            return child;
          },
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    expect(progress, isNotEmpty);
    expect(progress, everyElement(allOf(isNot(isNaN), inInclusiveRange(0.0, 1.0))));
  });

  testWidgets('CollapsibleWidget can detach during an animation without late updates', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CollapsibleWidget(
          expanded: true,
          duration: Duration(milliseconds: 300),
          child: SizedBox(width: 30, height: 20),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });

  testWidgets('KeyboardVisibilityObserver emits only changed metric states', (tester) async {
    final emitted = <KeyboardVisibility>[];
    final subscription = KeyboardVisibilityObserver.stream.listen(emitted.add);
    addTearDown(subscription.cancel);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: KeyboardVisibilityObserver(child: SizedBox()),
      ),
    );
    await tester.pump();
    expect(emitted, hasLength(1));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: KeyboardVisibilityObserver(child: SizedBox()),
      ),
    );
    await tester.pump();
    expect(emitted, hasLength(1));

    tester.view.viewInsets = const FakeViewPadding(bottom: 100);
    await tester.pump();
    expect(emitted, hasLength(2));

    tester.view.viewInsets = const FakeViewPadding(bottom: 100);
    await tester.pump();
    expect(emitted, hasLength(2));
  });

  testWidgets('KeyboardVisibilityObserver recalculates percent padding after view height changes', (tester) async {
    final emitted = <KeyboardVisibility>[];
    final subscription = KeyboardVisibilityObserver.stream.listen(emitted.add);
    addTearDown(subscription.cancel);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: KeyboardVisibilityObserver(child: SizedBox()),
      ),
    );
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 100);
    await tester.pump();
    expect(emitted.last.absolutePadding, 100);
    expect(emitted.last.percentPadding, closeTo(100 / 800, 0.000001));

    tester.view.physicalSize = const Size(400, 400);
    await tester.pump();
    expect(emitted.last.absolutePadding, 100);
    expect(emitted.last.percentPadding, closeTo(100 / 400, 0.000001));
  });

  testWidgets('Base64 image providers retain cache keys across equivalent widget rebuilds', (tester) async {
    const encoded = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL1xAAAAABJRU5ErkJggg==';

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Base64ImageWidget(imageEncoded: encoded),
      ),
    );
    final firstProvider = tester.widget<Image>(find.byType(Image)).image;

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Base64ImageWidget(imageEncoded: encoded),
      ),
    );
    final secondProvider = tester.widget<Image>(find.byType(Image)).image;

    expect(Base64ImageProvider(encoded), equals(Base64ImageProvider(encoded)));
    expect(firstProvider, equals(secondProvider));
    expect(firstProvider.hashCode, secondProvider.hashCode);
  });
}
