import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Image provider that returns a 1x1 transparent image.
class EmptyImageProvider extends ImageProvider<EmptyImageProvider> {
  /// Creates an empty image provider.
  const EmptyImageProvider();

  @override
  /// Returns this provider synchronously as the cache key.
  Future<EmptyImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<EmptyImageProvider>(this);
  }

  @override
  /// Loads a transparent 1x1 image.
  ImageStreamCompleter loadImage(EmptyImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(EmptyImageProvider key, ImageDecoderCallback decode) async {
    final recorder = ui.PictureRecorder();
    // ignore: unused_local_variable
    final canvas = Canvas(recorder);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    return ImageInfo(image: image);
  }
}
