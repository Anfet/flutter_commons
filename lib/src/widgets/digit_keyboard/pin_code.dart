import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_commons/flutter_commons.dart';

const _kDefaultMaxPinLength = 4;

typedef PinCodeBuilder = Widget Function(BuildContext context, String char);

class PinCode extends StatelessWidget {
  final int maxLength;
  final PinCodeController pinCodeController;
  final PinCodeBuilder builder;
  final double? spacing;

  const PinCode({
    super.key,
    this.maxLength = _kDefaultMaxPinLength,
    required this.pinCodeController,
    required this.builder,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        pinCodeController._focusNode.requestFocus();
      },
      child: IntrinsicHeight(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AbsorbPointer(
              child: Visibility(
                visible: false,
                maintainState: true,
                maintainSize: true,
                maintainAnimation: true,
                maintainInteractivity: true,
                child: SizedBox.shrink(
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
                    autofocus: false,
                    enabled: pinCodeController._isEnabled,
                    maxLines: 1,
                    scrollPadding: EdgeInsets.zero,
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
                    separatorBuilder: (index, item, list) => const Spacer(), //spacing == 0 ? null : (index, item, list) => HSpacer(spacing),
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

class PinCodeController extends ChangeNotifier with Logging {
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
    required String pin,
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
