import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const style = TextStyle(fontSize: 17, height: 1.25);

  group('TextUtils layout contract', () {
    testWidgets('textSpanSize matches an unconstrained rendered RichText exactly', (tester) async {
      const span = TextSpan(
        text: 'Bold ',
        style: style,
        children: [
          TextSpan(
            text: 'and normal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );

      final paragraph = await _renderParagraph(tester, span: span);

      expect(TextUtils.textSpanSize(span: span), paragraph.size);
    });

    testWidgets('textSize matches constrained multi-line rendered text exactly', (tester) async {
      const width = 96.0;
      const text = 'A constrained sentence that wraps across several rendered lines.';
      final paragraph = await _renderParagraph(tester, text: text, style: style, width: width);

      expect(TextUtils.textSize(text: text, style: style, width: width), paragraph.size);
      expect(paragraph.size.width, width);
      expect(paragraph.size.height, greaterThan(style.fontSize!));
    });

    testWidgets('textSpanSize matches right-to-left rendered text exactly', (tester) async {
      const width = 110.0;
      const span = TextSpan(text: 'אבג דהו זחט יכל', style: style);
      final paragraph = await _renderParagraph(
        tester,
        span: span,
        width: width,
        textDirection: TextDirection.rtl,
      );

      expect(
        TextUtils.textSpanSize(span: span, width: width, textDirection: TextDirection.rtl),
        paragraph.size,
      );
    });

    testWidgets('textSize matches RichText configured with a TextScaler', (tester) async {
      const width = 180.0;
      const text = 'Scaled paragraph';
      const scaler = TextScaler.linear(1.6);
      final paragraph = await _renderParagraph(
        tester,
        text: text,
        style: style,
        width: width,
        textScaler: scaler,
      );

      expect(
        TextUtils.textSize(text: text, style: style, width: width, textScaler: scaler),
        paragraph.size,
      );
    });

    testWidgets('textSize matches Text that reads its scaler from MediaQuery', (tester) async {
      const width = 180.0;
      const text = 'MediaQuery scaled paragraph';
      const scaler = TextScaler.linear(1.6);
      final paragraph = await _renderParagraph(
        tester,
        text: text,
        style: style,
        width: width,
        useMediaQueryTextScaler: true,
      );

      expect(
        TextUtils.textSize(text: text, style: style, width: width, textScaler: scaler),
        paragraph.size,
      );
    });

    testWidgets('textSize honors maxLines exactly like rendered text', (tester) async {
      const width = 74.0;
      const text = 'One two three four five six seven eight nine ten.';
      final paragraph = await _renderParagraph(tester, text: text, style: style, width: width, maxLines: 2);

      expect(TextUtils.textSize(text: text, style: style, width: width, maxLines: 2), paragraph.size);
      expect(_lineCount(text: text, style: style, width: width, maxLines: 2), 2);
    });

    testWidgets('textBoundingBoxSize matches rendered selection boxes for whitespace and newlines', (tester) async {
      const width = 75.0;
      const text = '  first  \n\nsecond   ';
      final paragraph = await _renderParagraph(tester, text: text, style: style, width: width);

      expect(
        TextUtils.textBoundingBoxSize(text: text, style: style, width: width),
        _selectionBounds(paragraph, text.length),
      );
      expect(
        TextUtils.textBoundingBoxSize(text: '', style: style, width: width),
        Size.zero,
      );
    });

    testWidgets('textLinesApprox counts laid-out empty and newline lines, not selection fragments', (tester) async {
      const width = 75.0;
      const text = 'first\n\nsecond trailing   ';
      await _renderParagraph(tester, text: text, style: style, width: width);

      expect(
        TextUtils.textLinesApprox(text: text, style: style, width: width),
        _lineCount(text: text, style: style, width: width),
      );
      expect(TextUtils.textLinesApprox(text: '', style: style, width: width), 0);
      expect(
        TextUtils.textLinesApprox(
          text: 'one two three four five six seven',
          style: style,
          width: width,
          maxLines: 2,
        ),
        2,
      );
    });

    test('textLinesApprox does not treat bidirectional selection fragments as lines', () {
      const text = 'Latin אבג Latin';

      expect(TextUtils.textLinesApprox(text: text, style: style), _lineCount(text: text, style: style, width: double.infinity));
      expect(TextUtils.textLinesApprox(text: text, style: style), 1);
    });

    test('textLinesApprox preserves the legacy scale-factor input when no TextScaler is supplied', () {
      const width = 90.0;
      const text = 'Legacy scale factor wraps across several lines.';

      expect(
        TextUtils.textLinesApprox(text: text, style: style, width: width, textScaleFactor: 2),
        _lineCount(text: text, style: style, width: width, textScaler: const TextScaler.linear(2)),
      );
    });

    test('textLinesApprox gives an explicit TextScaler precedence over the legacy scale factor', () {
      const width = 90.0;
      const text = 'Explicit scaler wraps across several rendered lines.';
      const scaler = TextScaler.linear(1.5);

      expect(
        TextUtils.textLinesApprox(text: text, style: style, width: width, textScaleFactor: 3, textScaler: scaler),
        _lineCount(text: text, style: style, width: width, textScaler: scaler),
      );
    });

    test('rejects widths and maxLines that cannot form a TextPainter layout', () {
      expect(
        () => TextUtils.textSize(text: 'text', style: style, width: double.nan),
        throwsArgumentError,
      );
      expect(
        () => TextUtils.textSize(text: 'text', style: style, width: -1),
        throwsArgumentError,
      );
      expect(
        () => TextUtils.textSize(text: 'text', style: style, width: double.negativeInfinity),
        throwsArgumentError,
      );
      expect(
        () => TextUtils.textSize(text: 'text', style: style, width: double.infinity),
        returnsNormally,
      );
      expect(
        () => TextUtils.textSize(text: 'text', style: style, maxLines: 0),
        throwsArgumentError,
      );
    });
  });
}

Future<RenderParagraph> _renderParagraph(
  WidgetTester tester, {
  InlineSpan? span,
  String? text,
  TextStyle? style,
  double? width,
  int? maxLines,
  TextScaler textScaler = TextScaler.noScaling,
  bool useMediaQueryTextScaler = false,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final richText = useMediaQueryTextScaler
      ? Text(text!, style: style, maxLines: maxLines)
      : RichText(
          text: span ?? TextSpan(text: text, style: style),
          maxLines: maxLines,
          textScaler: textScaler,
        );
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
      child: Directionality(
        textDirection: textDirection,
        child: Align(
          alignment: Alignment.topLeft,
          child: width == null
              ? richText
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: richText,
                ),
        ),
      ),
    ),
  );

  return tester.renderObject<RenderParagraph>(find.byType(RichText));
}

Size _selectionBounds(RenderParagraph paragraph, int textLength) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: textLength),
  );
  if (boxes.isEmpty) return Size.zero;

  var bounds = boxes.first.toRect();
  for (final box in boxes.skip(1)) {
    bounds = bounds.expandToInclude(box.toRect());
  }
  return bounds.size;
}

int _lineCount({
  required String text,
  required TextStyle style,
  required double width,
  int? maxLines,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    textScaler: textScaler,
  );
  try {
    painter.layout(maxWidth: width);
    return painter.computeLineMetrics().length;
  } finally {
    painter.dispose();
  }
}
