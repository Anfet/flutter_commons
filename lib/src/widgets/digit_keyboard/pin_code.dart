import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_commons/flutter_commons.dart';

const _kDefaultMaxPinLength = 4;

typedef PinCodeBuilder = Widget Function(BuildContext context, String char);

class PinCode extends StatelessWidget {
  final int maxLength;
  final PinCodeController pinCodeController;
  final PinCodeBuilder builder;
  final double spacing;
  final bool autofocus;
  final double height;
  final double? bottomPadding;

  const PinCode({
    super.key,
    this.maxLength = _kDefaultMaxPinLength,
    required this.pinCodeController,
    required this.builder,
    required this.height,
    this.spacing = 8,
    this.autofocus = true,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        pinCodeController._focusNode.requestFocus();
      },
      child: SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AbsorbPointer(
              child: Opacity(
                opacity: 0.0,
                child: SizedBox(
                  height: height,
                  child: TextField(
                    onChanged: (value) {
                      pinCodeController.pin = value;
                      if (value.length == maxLength) {
                        pinCodeController._focusNode.unfocus();
                      }
                    },
                    controller: pinCodeController._controller,
                    decoration: const InputDecoration.collapsed(hintText: '').copyWith(isDense: false),
                    style: const TextStyle(fontSize: 1),
                    autocorrect: false,
                    autofocus: autofocus,
                    enabled: pinCodeController._isEnabled,
                    maxLines: 1,
                    scrollPadding: EdgeInsets.only(bottom: (height ?? 0.0) + (bottomPadding ?? 0.0)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    maxLength: maxLength,
                    focusNode: pinCodeController._focusNode,
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge([pinCodeController, pinCodeController._controller]),
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: SeparatedList.builder(
                    List.generate(maxLength, (index) => pinCodeController.pin.ensureLength(maxLength)[index]),
                    builder: (index, item, list) => builder(context, item),
                    separatorBuilder: (index, item, list) => HSpacer(spacing),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PinCodeController extends ChangeNotifier {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  ValueChanged<String>? onPinChanged;

  bool _isEnabled;

  bool get isEnabled => _isEnabled;

  String _pin;

  String get pin => _pin;

  set pin(String value) {
    if (value != pin) {
      _pin = value;

      if (_controller.text != value) {
        _controller.text = value;
      }

      onPinChanged?.call(_pin);
    }
  }

  set isEnabled(bool value) {
    _isEnabled = value;
    notifyListeners();
  }

  PinCodeController({
    String pin = '',
    bool isEnabled = true,
    this.onPinChanged,
  })  : _pin = pin,
        _isEnabled = isEnabled {
    _controller.text = _pin;
  }

  void refresh() => notifyListeners();

  void focus() => _focusNode.requestFocus();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
