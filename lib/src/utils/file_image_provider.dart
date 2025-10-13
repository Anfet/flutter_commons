import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_commons/src/extensions/numeric_ext.dart';

class FileImageProvider extends ImageProvider<FileImageProvider> {
  final File file;

  FileImageProvider(this.file);

  @override
  Future<FileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(FileImageProvider key, ImageDecoderCallback decode) {
    final streamController = StreamController<ImageChunkEvent>();
    final codecCompleter = Completer<ui.Codec>();

    _loadAsync(key, decode, streamController, codecCompleter).catchError((ex, stack) {
      PaintingBinding.instance.imageCache.evict(key);
    });

    return MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
      debugLabel: file.path,
      chunkEvents: streamController.stream,
    );
  }

  Future<void> _loadAsync(
      FileImageProvider key, ImageDecoderCallback decode, StreamController<ImageChunkEvent> chunkStream, Completer<ui.Codec> codecCompleter) async {
    var exists = await file.exists();
    if (!exists) {
      throw FileSystemException('file does not exists', file.path);
    }

    var length = await file.length();
    chunkStream.add(ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: length));
    late ui.Codec codec;

    late Uint8List bytes;
    if (length < 1.mb) {
      bytes = await file.readAsBytes();
    } else {
      var read = 0;
      var buffer = WriteBuffer();
      await for (var bytes in file.openRead()) {
        buffer.putUint8List(Uint8List.fromList(bytes));
        read += bytes.length;
        var chunk = ImageChunkEvent(cumulativeBytesLoaded: min(read, length - 1), expectedTotalBytes: length);
        chunkStream.add(chunk);
      }

      bytes = buffer.done().buffer.asUint8List();
    }

    codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    chunkStream.add(ImageChunkEvent(cumulativeBytesLoaded: length, expectedTotalBytes: length));
    codecCompleter.complete(codec);
    await chunkStream.close();
  }

  @override
  bool operator ==(Object other) {
    return other is FileImageProvider && other.file.path == file.path;
  }

  @override
  int get hashCode => file.path.hashCode;
}
