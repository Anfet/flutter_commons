import 'package:flutter/widgets.dart';

class TextUtils {
  static Size textHeight(
    BuildContext context,
    String text,
    TextStyle textStyle, {
    double limitedWidth = double.infinity,
  }) {
    final painter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        maxLines: 1000,
        textScaleFactor: MediaQuery.of(context).textScaleFactor,
        textDirection: TextDirection.ltr);

    painter.layout(maxWidth: limitedWidth);
    return painter.size;
  }

  static int textLinesApprox(
    BuildContext context,
    String text,
    TextStyle textStyle, {
    double limitedWidth = double.infinity,
  }) {
    final scaleFactor = MediaQuery.of(context).textScaleFactor;
    final painter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        maxLines: 1000,
        textScaleFactor: scaleFactor,
        textDirection: TextDirection.ltr);

    painter.layout(maxWidth: limitedWidth);
    TextSelection selection = TextSelection(baseOffset: 0, extentOffset: text.length);
    List<TextBox> boxes = painter.getBoxesForSelection(selection);
    int numberOfLines = boxes.length;
    return numberOfLines;
  }
}
