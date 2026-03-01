// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';

const _defaultPinLength = 4; 

/// Builder for a single pin dot at [index].
typedef PinDotBuilder = Widget Function(BuildContext context, int index);

@immutable
/// Colors used by [PinDots] for different pin states.
class PinDotTheme {
  /// Color for entered symbols.
  final Color enteredColor;

  /// Color for empty symbols.
  final Color unenteredColor;

  /// Color used when confirmation succeeds.
  final Color successColor;

  /// Color used when confirmation fails.
  final Color errorColor;

  /// Creates a complete pin dot color theme.
  const PinDotTheme({
    required this.enteredColor,
    required this.unenteredColor,
    required this.successColor,
    required this.errorColor,
  });
}

/// Visual indicator that shows pin entry progress using dots.
class PinDots extends StatelessWidget {
  /// Number of dots to display.
  final int pinLength;

  /// Horizontal gap between dots.
  final double spacing;

  /// Builds individual dot widgets.
  late final PinDotBuilder pinBuilder;

  /// Creates dots with a custom [pinBuilder].
  PinDots.builder({
    super.key,
    this.pinLength = _defaultPinLength,
    required this.pinBuilder,
    this.spacing = 0,
  });

  /// Creates default circular dots from entered [pin] value.
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
  /// Builds a row of dot widgets with separators.
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

/// Controller for managing pin and confirmation input state.
class PinDotsController extends ChangeNotifier {
  String _pin = '';
  String _confirmation = '';

  /// Current pin value.
  String get pin => _pin;

  /// Current pin confirmation value.
  String get confirmation => _confirmation;

  /// Whether [pin] reached [pinLength].
  bool get isPinEntered => pin.length == pinLength;

  /// Whether [confirmation] reached [pinLength].
  bool get isConfirmationEntered => confirmation.length == pinLength;

  /// Whether entered values are complete and match.
  bool get isPinMatched => isPinEntered && (!withConfirmation || (isConfirmationEntered && pin == confirmation));

  /// Whether confirmation mode is enabled.
  final bool withConfirmation;

  /// Maximum pin length.
  final int pinLength;

  /// Called when pin entry is complete and valid.
  final TypedCallback<String> onPinEntered;

  /// Called when pin state changes but input is not complete yet.
  final VoidCallback? onPinChanged;

  /// Called when pin and confirmation are complete but do not match.
  final VoidCallback? onPinsNotMatch;

  /// Creates a pin controller with optional initial values.
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

  /// Updates [pin] with automatic truncation to [pinLength].
  set pin(String value) {
    var stripped = value.take(pinLength);
    if (stripped != _pin) {
      _pin = stripped;
      _onChanged();
    }
  }

  /// Updates [confirmation] with automatic truncation to [pinLength].
  set confirmation(String value) {
    var stripped = value.take(pinLength);
    if (_confirmation != stripped) {
      _confirmation = stripped;
      _onChanged();
    }
  }

  /// Clears both pin and confirmation values.
  void clear() {
    _confirmation = '';
    _pin = '';
    _onChanged();
  }

  /// Appends a digit to pin or confirmation depending on current state.
  void onDigitEntered(int digit) {
    if (pin.length < pinLength) {
      pin += '$digit';
    } else if (pin.length == pinLength && withConfirmation && confirmation.length < pinLength) {
      confirmation += '$digit';
    }
  }

  /// Removes one digit from confirmation or pin.
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

  /// Returns pin digit at [index] or empty string if missing.
  String pinDigit(int index) => index < pin.length ? pin[index] : '';

  /// Returns confirmation digit at [index] or empty string if missing.
  String confirmationDigit(int index) => index < confirmation.length ? confirmation[index] : '';
}
