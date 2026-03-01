import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Image provider that decodes a Base64-encoded image string.
class Base64ImageProvider extends ImageProvider<Base64ImageProvider> {
  /// Raw Base64-encoded image payload.
  final String encoded;

  /// Creates an image provider for [encoded].
  Base64ImageProvider(this.encoded);

  @override
  /// Returns this provider synchronously as the cache key.
  Future<Base64ImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<Base64ImageProvider>(this);
  }

  @override
  /// Loads and decodes image bytes from [encoded].
  ImageStreamCompleter loadImage(Base64ImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(Base64ImageProvider key, ImageDecoderCallback decode) async {
    var bytes = await compute<String, Uint8List>((encoded) => base64Decode(encoded), encoded);
    var image = await decodeImageFromList(bytes);
    return ImageInfo(image: image);
  }
}
