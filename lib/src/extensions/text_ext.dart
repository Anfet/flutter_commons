import 'package:flutter/widgets.dart';

/// The result of laying out a text paragraph.
///
/// [size] is a tight-layout fixed point: a [RichText] configured with the
/// same arguments and put in a [SizedBox] of this size has the same logical
/// [RenderParagraph] size. [didExceedMaxLines] reports intentional truncation
/// caused by [TextPainter.maxLines]; a [Size] alone cannot communicate that.
/// This requires the [SizedBox] to receive constraints that do not override
/// its dimensions and matching [PlaceholderDimensions] for every [WidgetSpan].
@immutable
class TextLayoutResult {
  const TextLayoutResult({
    required this.size,
    required this.lineCount,
    required this.didExceedMaxLines,
  });

  /// The logical size that is safe to use as tight constraints.
  final Size size;

  /// The number of visible, laid-out line metrics.
  final int lineCount;

  /// Whether the source text was truncated because of [TextPainter.maxLines].
  final bool didExceedMaxLines;

  /// Whether all text fits within the configured [TextPainter.maxLines].
  bool get fits => !didExceedMaxLines;
}

/// Measures text with the same layout rules used by [RenderParagraph].
///
/// Measurements are exact logical-pixel geometry for the current Flutter
/// engine, loaded fonts, and supplied paragraph configuration. They do not
/// guarantee physical-pixel raster bounds: glyph ink, shadows, and custom
/// foreground paints can overhang line boxes, and a later font/system-font
/// change can reflow text. A [WidgetSpan] requires [placeholderDimensions]
/// matching the dimensions produced by the real render tree.
///
/// If [TextLayoutResult.fits] is true and its [TextLayoutResult.size] is used
/// as unconstrained tight box dimensions, Flutter has no [RenderParagraph]
/// line-box overflow. This excludes ink and inline-widget child paint bounds.
class TextUtils {
  /// Returns the full tight-layout measurement for [span].
  ///
  /// [width] is the initial available maximum width. The returned [size] may
  /// be wider when [softWrap] is false (except for ellipsis), because that is
  /// how [RenderParagraph] avoids visual overflow for an unwrapped line.
  static TextLayoutResult textSpanLayout({
    required TextSpan span,
    double width = double.infinity,
    int? maxLines,
    TextDirection textDirection = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
    TextAlign textAlign = TextAlign.start,
    Locale? locale,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    TextHeightBehavior? textHeightBehavior,
    List<PlaceholderDimensions>? placeholderDimensions,
  }) => _layout(
    span: span,
    configuration: _TextLayoutConfiguration(
      width: width,
      maxLines: maxLines,
      textDirection: textDirection,
      textScaler: textScaler,
      textAlign: textAlign,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      placeholderDimensions: placeholderDimensions,
    ),
  );

  /// Returns the tight-layout measurement for a plain [text] paragraph.
  static TextLayoutResult textLayout({
    required String text,
    required TextStyle style,
    double width = double.infinity,
    int? maxLines,
    TextDirection textDirection = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
    TextAlign textAlign = TextAlign.start,
    Locale? locale,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    TextHeightBehavior? textHeightBehavior,
  }) => textSpanLayout(
    span: TextSpan(text: text, style: style),
    width: width,
    maxLines: maxLines,
    textDirection: textDirection,
    textScaler: textScaler,
    textAlign: textAlign,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    strutStyle: strutStyle,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
  );

  /// Measures a [Text] widget using inherited style and paragraph defaults.
  ///
  /// This mirrors [Text]'s style merge, accessibility bold-text adjustment,
  /// [MediaQuery] scaler, [DefaultTextStyle], [Directionality], locale, and
  /// [DefaultTextHeightBehavior] resolution. Mount a [Text] with the same
  /// explicit arguments in a [SizedBox] of the returned [TextLayoutResult.size]
  /// to satisfy the tight-layout contract.
  static TextLayoutResult textLayoutFor(
    BuildContext context, {
    required String text,
    TextStyle? style,
    double width = double.infinity,
    int? maxLines,
    TextDirection? textDirection,
    TextScaler? textScaler,
    double? textScaleFactor,
    TextAlign? textAlign,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    StrutStyle? strutStyle,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
  }) {
    _validateTextScaleFactor(textScaleFactor);
    if (textScaler != null && textScaleFactor != null) {
      throw ArgumentError('textScaler and textScaleFactor cannot both be specified.');
    }
    final defaultTextStyle = DefaultTextStyle.of(context);
    var effectiveStyle = style;
    if (style == null || style.inherit) {
      effectiveStyle = defaultTextStyle.style.merge(style);
    }
    if (MediaQuery.boldTextOf(context)) {
      effectiveStyle = effectiveStyle!.merge(const TextStyle(fontWeight: FontWeight.bold));
    }

    final effectiveScaler = textScaler ?? (textScaleFactor == null ? MediaQuery.textScalerOf(context) : TextScaler.linear(textScaleFactor));
    return textSpanLayout(
      span: TextSpan(text: text, style: effectiveStyle, locale: locale),
      width: width,
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      textDirection: textDirection ?? Directionality.of(context),
      textScaler: effectiveScaler,
      textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
      locale: locale ?? Localizations.maybeLocaleOf(context),
      softWrap: softWrap ?? defaultTextStyle.softWrap,
      overflow: overflow ?? effectiveStyle?.overflow ?? defaultTextStyle.overflow,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis ?? defaultTextStyle.textWidthBasis,
      textHeightBehavior: textHeightBehavior ?? defaultTextStyle.textHeightBehavior ?? DefaultTextHeightBehavior.maybeOf(context),
    );
  }

  /// Returns the tight paragraph size for [span].
  static Size textSpanSize({
    required TextSpan span,
    double width = double.infinity,
    int? maxLines,
    TextDirection textDirection = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
    TextAlign textAlign = TextAlign.start,
    Locale? locale,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    TextHeightBehavior? textHeightBehavior,
    List<PlaceholderDimensions>? placeholderDimensions,
  }) => textSpanLayout(
    span: span,
    width: width,
    maxLines: maxLines,
    textDirection: textDirection,
    textScaler: textScaler,
    textAlign: textAlign,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    strutStyle: strutStyle,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    placeholderDimensions: placeholderDimensions,
  ).size;

  /// Returns the tight paragraph size for [text] and [style].
  static Size textSize({
    required String text,
    required TextStyle style,
    double width = double.infinity,
    int? maxLines,
    TextDirection textDirection = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
    TextAlign textAlign = TextAlign.start,
    Locale? locale,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    TextHeightBehavior? textHeightBehavior,
  }) => textLayout(
    text: text,
    style: style,
    width: width,
    maxLines: maxLines,
    textDirection: textDirection,
    textScaler: textScaler,
    textAlign: textAlign,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    strutStyle: strutStyle,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
  ).size;

  /// Returns the union of Flutter selection boxes for the complete [text].
  ///
  /// This deliberately differs from [textSize]: it measures selectable run
  /// geometry, so whitespace and newlines use
  /// [TextPainter.getBoxesForSelection] semantics. An empty selection returns
  /// [Size.zero].
  static Size textBoundingBoxSize({
    required String text,
    required TextStyle style,
    double width = double.infinity,
    int? maxLines,
    TextDirection? textDirection,
    TextScaler? textScaler,
    TextAlign textAlign = TextAlign.start,
    Locale? locale,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    TextHeightBehavior? textHeightBehavior,
  }) {
    final configuration = _TextLayoutConfiguration(
      width: width,
      maxLines: maxLines,
      textDirection: textDirection ?? TextDirection.ltr,
      textScaler: textScaler ?? TextScaler.noScaling,
      textAlign: textAlign,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
    final painter = _createPainter(
      span: TextSpan(text: text, style: style),
      configuration: configuration,
    );
    try {
      _layoutTight(painter, configuration);
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      );
      if (boxes.isEmpty) return Size.zero;

      var bounds = boxes.first.toRect();
      for (final box in boxes.skip(1)) {
        bounds = bounds.expandToInclude(box.toRect());
      }
      return bounds.size;
    } finally {
      painter.dispose();
    }
  }

  /// Returns the number of visible, laid-out lines.
  ///
  /// Despite its historic name, this is not an approximation and does not count
  /// selection rectangles. An explicit [textScaler] takes precedence over the
  /// legacy [textScaleFactor].
  static int textLinesApprox({
    required String text,
    required TextStyle style,
    double? textScaleFactor,
    double width = double.infinity,
    int? maxLines,
    TextDirection? textDirection,
    TextScaler? textScaler,
    TextAlign textAlign = TextAlign.start,
    Locale? locale,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    TextHeightBehavior? textHeightBehavior,
  }) {
    _validateTextScaleFactor(textScaleFactor);
    return textLayout(
      text: text,
      style: style,
      width: width,
      maxLines: maxLines,
      textDirection: textDirection ?? TextDirection.ltr,
      textScaler: textScaler ?? (textScaleFactor == null ? TextScaler.noScaling : TextScaler.linear(textScaleFactor)),
      textAlign: textAlign,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    ).lineCount;
  }

  static TextLayoutResult _layout({
    required TextSpan span,
    required _TextLayoutConfiguration configuration,
  }) {
    final painter = _createPainter(span: span, configuration: configuration);
    try {
      _layoutTight(painter, configuration);
      return TextLayoutResult(
        size: painter.size,
        lineCount: painter.computeLineMetrics().length,
        didExceedMaxLines: painter.didExceedMaxLines,
      );
    } finally {
      painter.dispose();
    }
  }

  static TextPainter _createPainter({
    required TextSpan span,
    required _TextLayoutConfiguration configuration,
  }) {
    _validateWidth(configuration.width);
    _validateMaxLines(configuration.maxLines);
    final painter = TextPainter(
      text: span,
      textAlign: configuration.textAlign,
      textDirection: configuration.textDirection,
      textScaler: configuration.textScaler,
      maxLines: configuration.maxLines,
      ellipsis: configuration.overflow == TextOverflow.ellipsis ? '\u2026' : null,
      locale: configuration.locale,
      strutStyle: configuration.strutStyle,
      textWidthBasis: configuration.textWidthBasis,
      textHeightBehavior: configuration.textHeightBehavior,
    );
    if (configuration.placeholderDimensions != null) {
      painter.setPlaceholderDimensions(configuration.placeholderDimensions);
    }
    return painter;
  }

  static void _layoutTight(TextPainter painter, _TextLayoutConfiguration configuration) {
    painter.layout(maxWidth: _adjustMaxWidth(configuration.width, configuration));
    final tightWidth = painter.size.width;
    painter.layout(
      minWidth: tightWidth,
      maxWidth: _adjustMaxWidth(tightWidth, configuration),
    );
  }

  static double _adjustMaxWidth(double maxWidth, _TextLayoutConfiguration configuration) {
    return configuration.softWrap || configuration.overflow == TextOverflow.ellipsis ? maxWidth : double.infinity;
  }

  static void _validateWidth(double width) {
    if (width.isNaN || width < 0) {
      throw ArgumentError.value(width, 'width', 'Must be a finite non-negative value or double.infinity.');
    }
  }

  static void _validateMaxLines(int? maxLines) {
    if (maxLines != null && maxLines <= 0) {
      throw ArgumentError.value(maxLines, 'maxLines', 'Must be greater than zero.');
    }
  }

  static void _validateTextScaleFactor(double? textScaleFactor) {
    if (textScaleFactor != null && (!textScaleFactor.isFinite || textScaleFactor < 0)) {
      throw ArgumentError.value(textScaleFactor, 'textScaleFactor', 'Must be a finite non-negative value.');
    }
  }
}

class _TextLayoutConfiguration {
  const _TextLayoutConfiguration({
    required this.width,
    required this.maxLines,
    required this.textDirection,
    required this.textScaler,
    required this.textAlign,
    required this.locale,
    required this.softWrap,
    required this.overflow,
    required this.strutStyle,
    required this.textWidthBasis,
    required this.textHeightBehavior,
    this.placeholderDimensions,
  });

  final double width;
  final int? maxLines;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final TextAlign textAlign;
  final Locale? locale;
  final bool softWrap;
  final TextOverflow overflow;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final List<PlaceholderDimensions>? placeholderDimensions;
}
