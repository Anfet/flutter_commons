import 'package:flutter/material.dart';

@immutable
class FlatTextButton extends StatelessWidget {
  final Widget text;
  final VoidCallback? onTap;

  const FlatTextButton({Key? key, required this.text, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) => TextButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          fixedSize: MaterialStateProperty.all(const Size.fromHeight(48)),
        ),
        onPressed: onTap,
        child: text,
      );
}
