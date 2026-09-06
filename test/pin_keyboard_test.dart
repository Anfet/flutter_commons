import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_commons/flutter_commons.dart';

void main() {
  group('PinCode', () {
    testWidgets('rebuilds the hidden TextField when enabled changes', (tester) async {
      final controller = PinCodeController(isEnabled: true);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinCode(
              pinCodeController: controller,
              builder: (_, char) => Text(char),
              height: 48,
              autofocus: false,
            ),
          ),
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      controller.isEnabled = false;
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

      controller.isEnabled = true;
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

      await tester.tap(find.byType(PinCode));
      expect(tester.binding.focusManager.primaryFocus, isNotNull);
    });

    testWidgets('exposes safe localized progress semantics without PIN digits', (tester) async {
      final controller = PinCodeController(pin: '12');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinCode(
              pinCodeController: controller,
              builder: (_, char) => Text(char),
              height: 48,
              autofocus: false,
              semanticLabel: 'Security code',
              semanticHint: 'Enter six digits',
              progressBuilder: (_, entered, total) => '$entered/$total complete',
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == 'Security code'),
      );
      expect(semantics.properties.textField, isTrue);
      expect(semantics.properties.enabled, isTrue);
      expect(semantics.properties.value, '2/4 complete');
      expect(semantics.properties.hint, 'Enter six digits');
      expect(semantics.properties.onTap, isNotNull);
      expect(find.bySemanticsLabel('1'), findsNothing);
      expect(find.bySemanticsLabel('2'), findsNothing);

      controller.isEnabled = false;
      await tester.pump();
      final disabledSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == 'Security code'),
      );
      expect(disabledSemantics.properties.enabled, isFalse);
      expect(disabledSemantics.properties.onTap, isNull);
    });

    testWidgets('refreshes progress semantics after typed input', (tester) async {
      var callbackCalls = 0;
      final controller = PinCodeController(onPinChanged: (_) => callbackCalls++);
      var notifications = 0;
      controller.addListener(() => notifications++);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinCode(
              pinCodeController: controller,
              builder: (_, char) => Text(char),
              height: 48,
              autofocus: false,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == 'PIN code'),
      );
      expect(semantics.properties.value, '2 of 4 digits entered');
      expect(find.bySemanticsLabel('1'), findsNothing);
      expect(find.bySemanticsLabel('2'), findsNothing);
      expect(callbackCalls, 1);
      expect(notifications, 1);
    });

    testWidgets('refreshes progress semantics after programmatic input', (tester) async {
      var callbackCalls = 0;
      final controller = PinCodeController(onPinChanged: (_) => callbackCalls++);
      var notifications = 0;
      controller.addListener(() => notifications++);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinCode(
              pinCodeController: controller,
              builder: (_, char) => Text(char),
              height: 48,
              autofocus: false,
            ),
          ),
        ),
      );

      controller.pin = '12';
      await tester.pump();

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == 'PIN code'),
      );
      expect(semantics.properties.value, '2 of 4 digits entered');
      expect(find.bySemanticsLabel('1'), findsNothing);
      expect(find.bySemanticsLabel('2'), findsNothing);
      expect(callbackCalls, 1);
      expect(notifications, 1);

      controller.pin = '12';
      await tester.pump();
      expect(callbackCalls, 1);
      expect(notifications, 1);
    });
  });

  testWidgets('Enabling exposes one disabled non-actionable semantics node', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Enabling(
            enabled: false,
            child: InkButton(onTap: () {}, child: const Text('Continue')),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.text('Continue'));
    expect(node.getSemanticsData().flagsCollection.isEnabled, ui.Tristate.isFalse);
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isFalse);
  });

  group('PinDotsController', () {
    test('backspace notifies and invokes the change callback once', () {
      var changes = 0;
      final controller = PinDotsController(
        initialPin: '12',
        pinLength: 4,
        onPinEntered: (_) {},
        onPinChanged: () => changes++,
      );
      addTearDown(controller.dispose);

      controller.onBackspace();

      expect(controller.pin, '1');
      expect(changes, 1);
    });
  });

  group('DigitKeyboard semantics', () {
    testWidgets('exposes labeled digit and backspace actions', (tester) async {
      var digit = '';
      var backspaces = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DigitKeyboard(
              onTap: (value) => digit = value,
              onTapBackspace: () => backspaces++,
              onLongTapBackspace: () => backspaces += 10,
            ),
          ),
        ),
      );

      final digitSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == '1',
        ),
      );
      expect(digitSemantics.properties.button, isTrue);
      expect(digitSemantics.properties.onTap, isNotNull);
      digitSemantics.properties.onTap!();
      expect(digit, '1');

      final backspaceSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Backspace',
        ),
      );
      expect(backspaceSemantics.properties.button, isTrue);
      expect(backspaceSemantics.properties.onTap, isNotNull);
      expect(backspaceSemantics.properties.onLongPress, isNotNull);
      backspaceSemantics.properties.onTap!();
      backspaceSemantics.properties.onLongPress!();
      expect(backspaces, 11);
    });
  });
}
