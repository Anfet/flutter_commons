import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const style = TextStyle(fontSize: 17, height: 1.2);

  group('TextUtils tight-layout contract', () {
    testWidgets('a normal wrapped RichText fits exactly in its measured SizedBox', (tester) async {
      const width = 110.0;
      const span = TextSpan(text: 'A measured paragraph wraps without any layout or paint overflow.', style: style);
      final measurement = TextUtils.textSpanLayout(span: span, width: width);

      final paragraph = await _mount(tester, measurement.size, RichText(text: span));

      expect(paragraph.size, measurement.size);
      expect(measurement.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('textSize keeps its Size-only API tight-layout safe', (tester) async {
      const width = 118.0;
      const text = 'The legacy size API remains safe when used as tight constraints.';
      const strut = StrutStyle(fontSize: 19, height: 1.25, forceStrutHeight: true);
      final size = TextUtils.textSize(
        text: text,
        style: style,
        width: width,
        strutStyle: strut,
        textHeightBehavior: const TextHeightBehavior(applyHeightToLastDescent: false),
      );

      final paragraph = await _mount(
        tester,
        size,
        RichText(
          text: const TextSpan(text: text, style: style),
          strutStyle: strut,
          textHeightBehavior: const TextHeightBehavior(applyHeightToLastDescent: false),
        ),
      );

      expect(paragraph.size, size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('longestLine width basis is measured as a tight-layout fixed point', (tester) async {
      const width = 145.0;
      const span = TextSpan(text: 'One two three four five six seven eight nine ten eleven.', style: style);
      final measurement = TextUtils.textSpanLayout(
        span: span,
        width: width,
        textWidthBasis: TextWidthBasis.longestLine,
      );

      final paragraph = await _mount(
        tester,
        measurement.size,
        RichText(text: span, textWidthBasis: TextWidthBasis.longestLine),
      );

      expect(paragraph.size, measurement.size);
      expect(measurement.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WidgetSpan is tight-layout exact when matching placeholder dimensions are supplied', (tester) async {
      const placeholderSize = Size(28, 22);
      final span = TextSpan(
        text: 'Before ',
        style: style,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(width: placeholderSize.width, height: placeholderSize.height),
          ),
          TextSpan(text: ' after'),
        ],
      );
      const dimensions = [
        PlaceholderDimensions(size: placeholderSize, alignment: PlaceholderAlignment.middle),
      ];
      final measurement = TextUtils.textSpanLayout(
        span: span,
        width: 160,
        placeholderDimensions: dimensions,
      );

      final paragraph = await _mount(tester, measurement.size, RichText(text: span));

      expect(paragraph.size, measurement.size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('softWrap false returns the natural width needed to avoid paint overflow', (tester) async {
      const requestedWidth = 70.0;
      const span = TextSpan(text: 'This line must remain unwrapped.', style: style);
      final measurement = TextUtils.textSpanLayout(
        span: span,
        width: requestedWidth,
        softWrap: false,
        overflow: TextOverflow.visible,
      );

      final paragraph = await _mount(
        tester,
        measurement.size,
        RichText(text: span, softWrap: false, overflow: TextOverflow.visible),
      );

      expect(measurement.size.width, greaterThan(requestedWidth));
      expect(paragraph.size, measurement.size);
      expect(measurement.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('maxLines ellipsis exposes intentional truncation while its box still fits exactly', (tester) async {
      const width = 100.0;
      const span = TextSpan(text: 'One two three four five six seven eight nine ten eleven twelve.', style: style);
      final measurement = TextUtils.textSpanLayout(
        span: span,
        width: width,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

      final paragraph = await _mount(
        tester,
        measurement.size,
        RichText(text: span, maxLines: 2, overflow: TextOverflow.ellipsis),
      );

      expect(paragraph.size, measurement.size);
      expect(measurement.didExceedMaxLines, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bounding-box and line helpers use the same complete paragraph configuration', (tester) async {
      const width = 98.0;
      const text = '  first\nsecond trailing   ';
      const strut = StrutStyle(fontSize: 20, height: 1.3, forceStrutHeight: true);
      const heightBehavior = TextHeightBehavior(applyHeightToFirstAscent: false);
      const scaler = TextScaler.linear(1.2);
      final measurement = TextUtils.textLayout(
        text: text,
        style: style,
        width: width,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.end,
        locale: const Locale('he'),
        textScaler: scaler,
        strutStyle: strut,
        textHeightBehavior: heightBehavior,
      );

      final paragraph = await _mount(
        tester,
        measurement.size,
        RichText(
          text: const TextSpan(text: text, style: style),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.end,
          locale: const Locale('he'),
          textScaler: scaler,
          strutStyle: strut,
          textHeightBehavior: heightBehavior,
        ),
        textDirection: TextDirection.rtl,
      );

      expect(
        TextUtils.textBoundingBoxSize(
          text: text,
          style: style,
          width: width,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.end,
          locale: const Locale('he'),
          textScaler: scaler,
          strutStyle: strut,
          textHeightBehavior: heightBehavior,
        ),
        _selectionBounds(paragraph, text.length),
      );
      expect(
        TextUtils.textLinesApprox(
          text: text,
          style: style,
          width: width,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.end,
          locale: const Locale('he'),
          textScaler: scaler,
          strutStyle: strut,
          textHeightBehavior: heightBehavior,
        ),
        measurement.lineCount,
      );
    });

    testWidgets('strut, height behavior, locale, alignment, and RTL remain tight-layout exact', (tester) async {
      const width = 135.5;
      const span = TextSpan(text: 'אבג דהו זחט יכל מנס עף', style: style);
      const strut = StrutStyle(fontSize: 20, height: 1.4, forceStrutHeight: true);
      const heightBehavior = TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false);
      final measurement = TextUtils.textSpanLayout(
        span: span,
        width: width,
        textAlign: TextAlign.end,
        textDirection: TextDirection.rtl,
        locale: const Locale('he'),
        strutStyle: strut,
        textHeightBehavior: heightBehavior,
      );

      final paragraph = await _mount(
        tester,
        measurement.size,
        RichText(
          text: span,
          textAlign: TextAlign.end,
          textDirection: TextDirection.rtl,
          locale: const Locale('he'),
          strutStyle: strut,
          textHeightBehavior: heightBehavior,
        ),
        textDirection: TextDirection.rtl,
      );

      expect(paragraph.size, measurement.size);
      expect(measurement.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('context-aware measurement mirrors Text inherited style and MediaQuery scaler', (tester) async {
      late TextLayoutResult measurement;
      const text = 'Inherited style and MediaQuery scaler must fit exactly.';
      const styleOverride = TextStyle(fontWeight: FontWeight.w700);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: DefaultTextHeightBehavior(
                textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
                child: DefaultTextStyle(
                  style: const TextStyle(fontSize: 16, height: 1.25),
                  textAlign: TextAlign.center,
                  maxLines: 10,
                  child: Builder(
                    builder: (context) {
                      measurement = TextUtils.textLayoutFor(
                        context,
                        text: text,
                        style: styleOverride,
                        width: 130,
                      );
                      return SizedBox(
                        width: measurement.size.width,
                        height: measurement.size.height,
                        child: const Text(text, style: styleOverride),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final paragraph = tester.renderObject<RenderParagraph>(find.byType(RichText));
      expect(paragraph.size, measurement.size);
      expect(measurement.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('context-aware measurement rejects Text mutually exclusive scaler inputs', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                expect(
                  () => TextUtils.textLayoutFor(
                    context,
                    text: 'Text scale input',
                    textScaler: const TextScaler.linear(1.2),
                    textScaleFactor: 1.2,
                  ),
                  throwsArgumentError,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('fractional logical Size remains exact at a fractional device pixel ratio', (tester) async {
      tester.view.devicePixelRatio = 1.25;
      addTearDown(tester.view.resetDevicePixelRatio);
      const span = TextSpan(text: 'Fractional logical pixels', style: style);
      final measurement = TextUtils.textSpanLayout(span: span, width: 103.5);

      final paragraph = await _mount(tester, measurement.size, RichText(text: span));

      expect(paragraph.size, measurement.size);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<RenderParagraph> _mount(
  WidgetTester tester,
  Size size,
  RichText text, {
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: textDirection,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: size.width, height: size.height, child: text),
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
