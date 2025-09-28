import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show SynchronousFuture, compute;
import 'package:flutter/material.dart';

class Base64ImageWidget extends StatefulWidget {
  final String imageEncoded;
  final BoxFit boxFit;

  const Base64ImageWidget({
    super.key,
    required this.imageEncoded,
    this.boxFit = BoxFit.none,
  });

  @override
  State<Base64ImageWidget> createState() => _Base64ImageWidgetState();
}

class _Base64ImageWidgetState extends State<Base64ImageWidget> {
  late Base64ImageProvider _provider;
  late String imageEncoded = widget.imageEncoded;

  @override
  void initState() {
    _provider = Base64ImageProvider(imageEncoded);
    super.initState();
  }

  void update() {
    if (imageEncoded != widget.imageEncoded) {
      imageEncoded = widget.imageEncoded;
      _provider.update(imageEncoded);
    }
  }

  @override
  void didUpdateWidget(covariant Base64ImageWidget oldWidget) {
    update();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _provider,
      gaplessPlayback: true,
      fit: widget.boxFit,
    );
  }
}

class Base64ImageProvider extends ImageProvider<Base64ImageProvider> {
  final _completer = YuvImageStreamCompleter();

  Base64ImageProvider([String? encoded]) {
    if (encoded?.isNotEmpty == true) {
      update(encoded ?? '');
    }
  }

  void update(String encoded) => _completer.update(encoded);

  @override
  Future<Base64ImageProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(Base64ImageProvider key, ImageDecoderCallback decode) => _completer;
}

class YuvImageStreamCompleter extends ImageStreamCompleter {
  void update(String encoded) async {
    var bytes = await compute<String, Uint8List>((encoded) => base64Decode(encoded), encoded);
    var image = await decodeImageFromList(bytes);
    setImage(ImageInfo(image: image));
  }
}
