import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class WidgetExporter {
  WidgetExporter._();

  /// Creates an image from the given widget by first spinning up a element and render tree,
  /// then waiting for the given [wait] amount of time and then creating an image via a [RepaintBoundary].
  ///
  /// The final image will be of size [imageSize] and the the widget will be layout, ... with the given [logicalSize].
  static Future<Uint8List?> createImageFromWidget(ui.FlutterView flutterView, Widget widget,
      {Duration? wait, Size? logicalSize, Size? imageSize}) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    logicalSize ??= flutterView.physicalSize / flutterView.devicePixelRatio;
    imageSize ??= flutterView.physicalSize;

    assert(logicalSize.aspectRatio == imageSize.aspectRatio);

    final RenderView renderView = RenderView(
      view: flutterView,
      child: RenderPositionedBox(alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        size: logicalSize,
        devicePixelRatio: 1.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(
      focusManager: FocusManager(),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);

    if (wait != null) {
      await Future.delayed(wait);
    }

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(pixelRatio: imageSize.width / logicalSize.width);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }
}
