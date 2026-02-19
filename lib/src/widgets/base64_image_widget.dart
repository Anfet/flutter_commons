import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show SynchronousFuture, compute;
import 'package:flutter/material.dart';

class Base64ImageWidget extends StatelessWidget {
  final String imageEncoded;
  final BoxFit boxFit;

  const Base64ImageWidget({
    super.key,
    required this.imageEncoded,
    this.boxFit = BoxFit.none,
  });

  @override
  Widget build(BuildContext context) {
    return Image(
      image: Base64ImageProvider(imageEncoded),
      gaplessPlayback: true,
      fit: boxFit,
    );
  }
}

class Base64ImageProvider extends ImageProvider<Base64ImageProvider> {
  final String encoded;

  Base64ImageProvider(this.encoded);

  @override
  Future<Base64ImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<Base64ImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(Base64ImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(Base64ImageProvider key, ImageDecoderCallback decode) async {
    var bytes = await compute<String, Uint8List>((encoded) => base64Decode(encoded), encoded);
    var image = await decodeImageFromList(bytes);
    return ImageInfo(image: image);
  }
}
