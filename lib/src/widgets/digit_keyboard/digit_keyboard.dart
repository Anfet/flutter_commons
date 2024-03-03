import 'package:flutter/material.dart';

const _kDigitPlaceholderWidth = 96.0;
const _kDigitHeight = 80.0;

class DigitKeyboard extends StatelessWidget {
  final ValueSetter<String> onTap;
  final VoidCallback onTapBackspace;
  final VoidCallback onLongTapBackspace;
  final Widget? leftButton;
  final Widget? rightButton;
  final TextStyle? digitStyle;

  const DigitKeyboard({
    required this.onTap,
    required this.onTapBackspace,
    required this.onLongTapBackspace,
    this.leftButton,
    this.rightButton,
    this.digitStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kDigitPlaceholderWidth * 3,
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 0,
          childAspectRatio: 1.0,
          crossAxisSpacing: 0,
          mainAxisExtent: _kDigitHeight,
        ),
        children: [
          _KeyButton(val: '1', onTap: onTap, digitStyle: digitStyle),
          _KeyButton(val: '2', onTap: onTap, digitStyle: digitStyle),
          _KeyButton(val: '3', onTap: onTap, digitStyle: digitStyle),
          _KeyButton(val: '4', onTap: onTap, digitStyle: digitStyle),
          _KeyButton(val: '5', onTap: onTap, digitStyle: digitStyle),
          _KeyButton(val: '6', onTap: onTap, digitStyle: digitStyle),
          _KeyButton(val: '7', onTap: onTap, digitStyle: digitStyle),
          _KeyButton(val: '8', onTap: onTap, digitStyle: digitStyle),
          _KeyButton(val: '9', onTap: onTap, digitStyle: digitStyle),
          leftButton ?? const _EmptyButton(),
          _KeyButton(val: '0', onTap: onTap, digitStyle: digitStyle),
          rightButton ?? _Backspace(onTap: onTapBackspace, onLongTap: onLongTapBackspace),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final Function(String) onTap;
  final String val;
  final TextStyle? digitStyle;

  const _KeyButton({
    required this.val,
    required this.onTap,
    this.digitStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(_kDigitHeight / 2),
        onTap: () => onTap(val),
        child: SizedBox(
          width: _kDigitPlaceholderWidth,
          height: _kDigitHeight,
          child: Center(
            child: Text(val, style: digitStyle),
          ),
        ),
      ),
    );
  }
}

class _EmptyButton extends StatelessWidget {
  const _EmptyButton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: _kDigitHeight,
    );
  }
}

class _Backspace extends StatelessWidget {
  final Function() onTap;
  final Function() onLongTap;

  const _Backspace({
    required this.onTap,
    required this.onLongTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        splashColor: Colors.black12,
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        onLongPress: onLongTap,
        child: const SizedBox(
          width: _kDigitPlaceholderWidth,
          height: _kDigitHeight,
          child: Center(
            child: Icon(Icons.backspace_outlined, size: 24),
          ),
        ),
      ),
    );
  }
}
