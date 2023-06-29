import 'package:flutter/widgets.dart';
import 'package:siberian_core/src/consts.dart';

class TextUtils {
  static Size textHeight({
    required String text,
    required TextStyle style,
    double? textScaleFactor,
    double width = double.infinity,
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines ?? Ints.maxInt,
      textScaleFactor: textScaleFactor ?? 1.0,
      textDirection: TextDirection.ltr,
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
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines ?? Ints.maxInt,
      textScaleFactor: textScaleFactor ?? 1.0,
      textDirection: TextDirection.ltr,
    );

    painter.layout(maxWidth: width);
    TextSelection selection = TextSelection(baseOffset: 0, extentOffset: text.length);
    List<TextBox> boxes = painter.getBoxesForSelection(selection);
    int numberOfLines = boxes.length;
    return numberOfLines;
  }
}
