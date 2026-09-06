import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports documented first-party logging and keyboard symbols', () {
    final logger = logMessage;
    final keyboard = DigitKeyboard(
      onTap: (_) {},
      onTapBackspace: () {},
      onLongTapBackspace: () {},
    );
    final visibility = const KeyboardVisibility(isVisible: false, absolutePadding: 0.0, percentPadding: 0.0);
    final observer = const KeyboardVisibilityObserver(child: SizedBox());
    final builder = const KeyboardVisibilityBuilder();
    final pinCodeController = PinCodeController();
    final pinDotsController = PinDotsController(onPinEntered: (_) {});

    addTearDown(pinCodeController.dispose);
    addTearDown(pinDotsController.dispose);

    expect(logger, isNotNull);
    expect(keyboard, isA<DigitKeyboard>());
    expect(visibility.isVisible, isFalse);
    expect(observer, isA<KeyboardVisibilityObserver>());
    expect(builder, isA<KeyboardVisibilityBuilder>());
  });
}
