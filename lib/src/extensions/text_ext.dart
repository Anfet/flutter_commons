import 'package:flutter/widgets.dart';
import 'package:flutter_commons/src/consts.dart';

class TextUtils {
  static Size textHeight({
    required String text,
    required TextStyle style,
    double width = double.infinity,
    int? maxLines,
    TextDirection? textDirection,
    TextScaler? textScaler,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines ?? Ints.maxInt,
      textScaler: textScaler ?? TextScaler.noScaling,
      textDirection: textDirection ?? TextDirection.ltr,
    );

    painter.layout(maxWidth: width);
    return painter.size;
  }

  static int textLinesApprox({
    required String text,
    required TextStyle style,
    double? textScaleFactor,
    double width = double.infinity,
    int? maxLines,
    TextDirection? textDirection,
    TextScaler? textScaler,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines ?? Ints.maxInt,
      textScaler: textScaler ?? TextScaler.noScaling,
      textDirection: textDirection ?? TextDirection.ltr,
    );

    painter.layout(maxWidth: width);
    TextSelection selection = TextSelection(baseOffset: 0, extentOffset: text.length);
    List<TextBox> boxes = painter.getBoxesForSelection(selection);
    int numberOfLines = boxes.length;
    return numberOfLines;
  }
}
