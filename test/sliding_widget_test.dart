import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const slidingKey = Key('sliding');
  const duration = Duration(milliseconds: 100);

  Widget buildSliding({
    Key key = slidingKey,
    SlidingOrientation orientation = SlidingOrientation.leftToRight,
    Curve curve = Curves.linear,
    SlidingPosition position = SlidingPosition.start,
    Duration? delay,
    SlidingTransitionBuilder? builder,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SlidingWidget(
        key: key,
        orientation: orientation,
        duration: duration,
        curve: curve,
        slidingPosition: position,
        delay: delay,
        builder: builder,
        child: const SizedBox(width: 20, height: 20),
      ),
    );
  }

  FractionalTranslation transition(WidgetTester tester) {
    return tester.widget<FractionalTranslation>(find.byType(FractionalTranslation));
  }

  testWidgets('animates from start and places end at rest', (tester) async {
    await tester.pumpWidget(buildSliding());
    expect(transition(tester).translation, const Offset(-1, 0));

    await tester.pump(const Duration(microseconds: 1));
    await tester.pump(duration ~/ 2);
    expect(transition(tester).translation.dx, inExclusiveRange(-1.0, 0.0));

    await tester.pump(duration ~/ 2);
    expect(transition(tester).translation, Offset.zero);

    await tester.pumpWidget(buildSliding(position: SlidingPosition.end));
    expect(transition(tester).translation, Offset.zero);

    await tester.pumpWidget(buildSliding(position: SlidingPosition.start));
    expect(transition(tester).translation, const Offset(-1, 0));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disposes replaced curve animations across repeated updates', (tester) async {
    Animation<double>? currentAnimation;
    Widget builder(BuildContext context, Widget? child, Animation<double> animation) {
      currentAnimation = animation;
      return child!;
    }

    const delay = Duration(hours: 1);
    await tester.pumpWidget(buildSliding(delay: delay, builder: builder));
    final firstAnimation = currentAnimation! as CurvedAnimation;
    expect(firstAnimation.curve, Curves.linear);
    expect(transition(tester).translation, const Offset(-1, 0));

    await tester.pumpWidget(
      buildSliding(
        orientation: SlidingOrientation.bottomToTop,
        curve: Curves.easeIn,
        delay: delay,
        builder: builder,
      ),
    );
    final secondAnimation = currentAnimation! as CurvedAnimation;
    expect(firstAnimation.isDisposed, isTrue);
    expect(secondAnimation.isDisposed, isFalse);
    expect(secondAnimation.curve, Curves.easeIn);
    expect(transition(tester).translation, const Offset(0, 1));

    await tester.pumpWidget(
      buildSliding(
        orientation: SlidingOrientation.rightToLeft,
        curve: Curves.easeOut,
        delay: delay,
        builder: builder,
      ),
    );
    final thirdAnimation = currentAnimation! as CurvedAnimation;
    expect(secondAnimation.isDisposed, isTrue);
    expect(thirdAnimation.isDisposed, isFalse);
    expect(thirdAnimation.curve, Curves.easeOut);
    expect(transition(tester).translation, const Offset(1, 0));

    await tester.pumpWidget(const SizedBox());
    expect(thirdAnimation.isDisposed, isTrue);
  });

  testWidgets('cancels a long pending delay when removed', (tester) async {
    await tester.pumpWidget(buildSliding(delay: const Duration(days: 1)));
    await tester.pumpWidget(const SizedBox());

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not forward a stale delayed start after moving to end', (tester) async {
    const delay = Duration(seconds: 1);
    await tester.pumpWidget(buildSliding(delay: delay));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(buildSliding(position: SlidingPosition.end, delay: delay));
    expect(transition(tester).translation, Offset.zero);

    await tester.pump(delay * 2);
    expect(transition(tester).translation, Offset.zero);
  });
}
