// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

const _defaultPinLength = 4;
const _defaultPinSize = 16.0;

typedef PinDotBuilder = Widget Function(BuildContext context, int index);

@immutable
class PinDotTheme {
  final Color enteredColor;
  final Color unenteredColor;
  final Color successColor;
  final Color errorColor;

  const PinDotTheme({
    required this.enteredColor,
    required this.unenteredColor,
    required this.successColor,
    required this.errorColor,
  });
}

class PinDots extends StatelessWidget {
  final int pinLength;
  final double spacing;
  late final PinDotBuilder pinBuilder;

  PinDots.builder({
    super.key,
    this.pinLength = _defaultPinLength,
    required this.pinBuilder,
    this.spacing = 0,
  });

  PinDots({
    super.key,
    required String pin,
    required double size,
    this.pinLength = _defaultPinLength,
    this.spacing = 0,
    PinDotTheme? theme,
    bool isSuccess = false,
  }) {
    pinBuilder = (BuildContext context, int index) {
      return _PinDot(
        color: pin.length == pinLength
            ? (isSuccess ? theme?.successColor ?? Theme.of(context).colorScheme.primary : theme?.errorColor ?? Theme.of(context).colorScheme.error)
            : (index < pin.length
                ? theme?.enteredColor ?? Theme.of(context).colorScheme.primary
                : theme?.unenteredColor ?? Theme.of(context).colorScheme.secondary),
        size: size,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: SeparatedList.builder(
        List.generate(
          pinLength,
          (index) => pinBuilder(context, index),
        ),
        builder: (index, item, list) => item,
        separatorBuilder: (index, item, list) => HSpacer(spacing),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  final Color color;
  final double size;

  const _PinDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 500.milliseconds,
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class PinDotsController extends ChangeNotifier {
  String _pin = '';
  String _confirmation = '';

  String get pin => _pin;

  String get confirmation => _confirmation;

  bool get isPinEntered => pin.length == pinLength;

  bool get isConfirmationEntered => confirmation.length == pinLength;

  bool get isPinMatched => isPinEntered && (!withConfirmation || (isConfirmationEntered && pin == confirmation));

  final bool withConfirmation;
  final int pinLength;

  final TypedCallback<String> onPinEntered;
  final VoidCallback? onPinChanged;
  final VoidCallback? onPinsNotMatch;

  PinDotsController({
    String initialPin = '',
    String initialConfirmation = '',
    this.withConfirmation = false,
    this.pinLength = _defaultPinLength,
    required this.onPinEntered,
    this.onPinsNotMatch,
    this.onPinChanged,
  })  : _pin = initialPin,
        _confirmation = initialConfirmation;

  set pin(String value) {
    var stripped = value.take(pinLength);
    if (stripped != _pin) {
      _pin = stripped;
      _onChanged();
    }
  }

  set confirmation(String value) {
    var stripped = value.take(pinLength);
    if (_confirmation != stripped) {
      _confirmation = stripped;
      _onChanged();
    }
  }

  void clear() {
    _confirmation = '';
    _pin = '';
    _onChanged();
  }

  void onDigitEntered(int digit) {
    if (pin.length < pinLength) {
      pin += '$digit';
    } else if (pin.length == pinLength && withConfirmation && confirmation.length < pinLength) {
      confirmation += '$digit';
    }
  }

  void onBackspace() {
    if (withConfirmation && confirmation.isNotEmpty) {
      confirmation = confirmation.take(confirmation.length - 1);
    } else if (pin.isNotEmpty) {
      pin = pin.take(pin.length - 1);
    }

    _onChanged();
  }

  void _onChanged() {
    notifyListeners();
    if (pin.length == pinLength && (!withConfirmation || confirmation.length == pinLength)) {
      if (pin == confirmation || !withConfirmation) {
        onPinEntered(pin);
      } else {
        onPinsNotMatch?.call();
      }
    } else {
      onPinChanged?.call();
    }
  }

  String pinDigit(int index) => index < pin.length ? pin[index] : '';

  String confirmationDigit(int index) => index < confirmation.length ? confirmation[index] : '';
}
