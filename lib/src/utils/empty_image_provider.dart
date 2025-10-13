import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EmptyImageProvider extends ImageProvider<EmptyImageProvider> {
  const EmptyImageProvider();

  @override
  Future<EmptyImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<EmptyImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(EmptyImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(EmptyImageProvider key, ImageDecoderCallback decode) async {
    final recorder = ui.PictureRecorder();
    // final canvas = Canvas(recorder);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    return ImageInfo(image: image);
  }
}
