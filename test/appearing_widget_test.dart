import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const duration = Duration(milliseconds: 120);
  const appearingKey = Key('appearing');
  const childSize = Size(100, 40);
  const keyA = Key('a');
  const keyB = Key('b');

  Widget appFor(ValueNotifier<Widget?> notifier) {
    return MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<Widget?>(
          valueListenable: notifier,
          builder: (context, child, _) {
            return Center(
              child: AppearingWidget(
                key: appearingKey,
                alignment: Alignment.topCenter,
                duration: duration,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('null -> show -> hide updates presence, size and opacity', (tester) async {
    final notifier = ValueNotifier<Widget?>(null);
    await tester.pumpWidget(appFor(notifier));

    expect(tester.getSize(find.byKey(appearingKey)), Size.zero);
    expect(find.byKey(keyA), findsNothing);

    notifier.value = const SizedBox(key: keyA, width: 100, height: 40);
    await tester.pump();
    expect(find.byKey(keyA), findsOneWidget);

    await tester.pump(duration ~/ 2);
    final midShowSize = tester.getSize(find.byKey(appearingKey));
    expect(midShowSize.width, childSize.width);
    expect(midShowSize.height, inInclusiveRange(0.0, childSize.height));
    final midShowOpacity =
        tester.widget<Opacity>(find.descendant(of: find.byKey(appearingKey), matching: find.byType(Opacity))).opacity;
    expect(midShowOpacity, inInclusiveRange(0.0, 1.0));

    await tester.pump(duration);
    expect(tester.getSize(find.byKey(appearingKey)), childSize);
    final shownOpacity = tester.widget<Opacity>(find.descendant(of: find.byKey(appearingKey), matching: find.byType(Opacity))).opacity;
    expect(shownOpacity, 1.0);
    expect(find.byKey(keyA), findsOneWidget);

    notifier.value = null;
    await tester.pump();
    expect(find.byKey(keyA), findsOneWidget);

    await tester.pump(duration ~/ 2);
    final midHideOpacity =
        tester.widget<Opacity>(find.descendant(of: find.byKey(appearingKey), matching: find.byType(Opacity))).opacity;
    expect(midHideOpacity, inInclusiveRange(0.0, 1.0));

    await tester.pump(duration);
    expect(tester.getSize(find.byKey(appearingKey)), Size.zero);
    expect(find.byKey(keyA), findsNothing);
  });

  testWidgets('replacing child during hide does not clear new child', (tester) async {
    final notifier = ValueNotifier<Widget?>(const Text('A', key: keyA));
    await tester.pumpWidget(appFor(notifier));
    await tester.pumpAndSettle();

    notifier.value = null;
    await tester.pump();
    expect(find.byKey(keyA), findsOneWidget);

    notifier.value = const Text('B', key: keyB);
    await tester.pump();
    expect(find.byKey(keyB), findsOneWidget);

    await tester.pump(duration * 2);
    expect(find.byKey(keyB), findsOneWidget);
  });
}
