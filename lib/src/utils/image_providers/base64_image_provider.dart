import 'dart:convert';
import 'dart:ui' as ui;

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
    final bytes = await compute<String, Uint8List>((encoded) => base64Decode(encoded), key.encoded);
    final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    try {
      final frame = await codec.getNextFrame();
      return ImageInfo(image: frame.image);
    } finally {
      codec.dispose();
    }
  }

  @override
  bool operator ==(Object other) => other is Base64ImageProvider && other.encoded == encoded;

  @override
  int get hashCode => encoded.hashCode;
}
