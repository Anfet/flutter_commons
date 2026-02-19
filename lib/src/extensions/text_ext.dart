import 'package:flutter/widgets.dart';
import 'package:flutter_commons/src/consts.dart';

class TextUtils {
  static Size textSpanSize({
    required TextSpan span,
    double width = double.infinity,
    int? maxLines,
    TextDirection textDirection = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final painter = TextPainter(
      text: span,
      maxLines: maxLines,
      textScaler: textScaler,
      textDirection: textDirection,
    );

    painter.layout(maxWidth: width);

    return painter.size;
  }

  static Size textSize({
    required String text,
    required TextStyle style,
    double width = double.infinity,
    int? maxLines,
    TextDirection textDirection = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
  }) =>
      textSpanSize(span: TextSpan(text: text, style: style), width: width, maxLines: maxLines, textDirection: textDirection, textScaler: textScaler);

  static Size textBoundingBoxSize({
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
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );

    if (boxes.isEmpty) return Size.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final box in boxes) {
      if (box.left < minX) minX = box.left;
      if (box.top < minY) minY = box.top;
      if (box.right > maxX) maxX = box.right;
      if (box.bottom > maxY) maxY = box.bottom;
    }

    return Size(maxX - minX, maxY - minY);
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
