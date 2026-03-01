
import 'package:flutter/material.dart';
import 'package:flutter_commons/src/utils/image_providers/base64_image_provider.dart';

/// Stateless widget that renders an image from a Base64 string.
class Base64ImageWidget extends StatelessWidget {
  /// Base64-encoded image data.
  final String imageEncoded;

  /// How to inscribe the image into the available space.
  final BoxFit boxFit;

  /// Creates a widget that decodes and renders [imageEncoded].
  const Base64ImageWidget({
    super.key,
    required this.imageEncoded,
    this.boxFit = BoxFit.none,
  });

  @override
  /// Builds an [Image] backed by [Base64ImageProvider].
  Widget build(BuildContext context) {
    return Image(
      image: Base64ImageProvider(imageEncoded),
      gaplessPlayback: true,
      fit: boxFit,
    );
  }
}
