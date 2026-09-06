import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    EmptyImageProvider.debugPictureToImage = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('Base64ImageProvider honors ResizeImage target dimensions', (tester) async {
    final encoded = (await tester.runAsync(() => _pngBase64(width: 80, height: 40)))!;
    final provider = ResizeImage(Base64ImageProvider(encoded), width: 20, height: 10);

    final imageInfo = (await tester.runAsync(() => _loadImage(provider)))!;

    expect(imageInfo.image.width, 20);
    expect(imageInfo.image.height, 10);
    imageInfo.dispose();
  });

  test('FileImageProvider keys compare by file path', () async {
    final provider = FileImageProvider(File('image.png'));
    final equalProvider = FileImageProvider(File('image.png'));
    final otherProvider = FileImageProvider(File('other.png'));

    final key = provider.obtainKey(ImageConfiguration.empty);

    expect(key, isA<SynchronousFuture<FileImageProvider>>());
    expect(await key, same(provider));
    expect(provider, equalProvider);
    expect(provider.hashCode, equalProvider.hashCode);
    expect(provider, isNot(otherProvider));
    expect(provider, isNot(File('image.png')));
  });

  testWidgets('FileImageProvider decodes a small image file', (tester) async {
    late Directory directory;
    final imageInfo = await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('file_image_provider_test.');
      final file = File('${directory.path}${Platform.pathSeparator}small.png');
      final encoded = await _pngBase64(width: 7, height: 5);
      await file.writeAsBytes(base64Decode(encoded));

      return _loadImage(FileImageProvider(file));
    });
    addTearDown(() => directory.delete(recursive: true));

    expect(imageInfo!.image.width, 7);
    expect(imageInfo.image.height, 5);
    imageInfo.dispose();
  });

  testWidgets('FileImageProvider reports a missing file error', (tester) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('file_image_provider_test.'),
    ))!;
    addTearDown(() => directory.delete(recursive: true));
    final missingFile = File('${directory.path}${Platform.pathSeparator}missing.png');
    final previousOnError = FlutterError.onError;
    final errors = <Object>[];
    FlutterError.onError = (details) {
      errors.add(details.exception);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.runAsync(() => _loadImage(FileImageProvider(missingFile)));

    expect(errors, hasLength(1));
    expect(errors.single, isA<FileSystemException>());
    expect((errors.single as FileSystemException).path, missingFile.path);
  });

  testWidgets('EmptyImageProvider disposes its Picture after rasterization', (tester) async {
    final events = <String>[];
    final previousOnCreate = ui.Picture.onCreate;
    final previousOnDispose = ui.Picture.onDispose;
    ui.Picture.onCreate = (picture) {
      events.add('create');
      previousOnCreate?.call(picture);
    };
    ui.Picture.onDispose = (picture) {
      events.add('dispose');
      previousOnDispose?.call(picture);
    };
    addTearDown(() {
      ui.Picture.onCreate = previousOnCreate;
      ui.Picture.onDispose = previousOnDispose;
    });

    final imageInfo = (await tester.runAsync(() => _loadEmptyImage(const EmptyImageProvider())))!;

    expect(events, equals(<String>['create', 'dispose']));
    imageInfo.dispose();
  });

  testWidgets('EmptyImageProvider disposes its Picture when rasterization fails', (tester) async {
    final events = <String>[];
    final previousOnCreate = ui.Picture.onCreate;
    final previousOnDispose = ui.Picture.onDispose;
    ui.Picture.onCreate = (picture) {
      events.add('create');
      previousOnCreate?.call(picture);
    };
    ui.Picture.onDispose = (picture) {
      events.add('dispose');
      previousOnDispose?.call(picture);
    };
    addTearDown(() {
      ui.Picture.onCreate = previousOnCreate;
      ui.Picture.onDispose = previousOnDispose;
    });
    final previousOnError = FlutterError.onError;
    final errors = <Object>[];
    FlutterError.onError = (details) {
      errors.add(details.exception);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
    EmptyImageProvider.debugPictureToImage = (_) => Future<ui.Image>.error(StateError('rasterization failed'));

    await tester.runAsync(() => _loadEmptyImage(const EmptyImageProvider()));

    expect(errors, contains(isA<StateError>()));
    expect(events, equals(<String>['create', 'dispose']));
  });
}

Future<ImageInfo> _loadImage<T extends Object>(ImageProvider<T> provider) {
  final imageStream = provider.resolve(ImageConfiguration.empty);
  return _listenToImageStream(imageStream);
}

Future<ImageInfo> _loadEmptyImage(EmptyImageProvider provider) {
  // ignore: invalid_use_of_protected_member
  final completer = provider.loadImage(provider, _unusedDecoder);
  final result = Completer<ImageInfo>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (imageInfo, synchronousCall) {
      completer.removeListener(listener);
      result.complete(imageInfo);
    },
    onError: (exception, stackTrace) {
      completer.removeListener(listener);
      result.completeError(exception, stackTrace);
    },
  );
  completer.addListener(listener);
  return result.future;
}

Future<ui.Codec> _unusedDecoder(ui.ImmutableBuffer buffer, {ui.TargetImageSizeCallback? getTargetSize}) {
  return Future<ui.Codec>.error(UnimplementedError());
}

Future<ImageInfo> _listenToImageStream(ImageStream imageStream) {
  final result = Completer<ImageInfo>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (imageInfo, synchronousCall) {
      imageStream.removeListener(listener);
      result.complete(imageInfo);
    },
    onError: (exception, stackTrace) {
      imageStream.removeListener(listener);
      result.completeError(exception, stackTrace);
    },
  );
  imageStream.addListener(listener);
  return result.future;
}

Future<String> _pngBase64({required int width, required int height}) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(const Color(0xFF123456), BlendMode.src);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(width, height);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return base64Encode(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}
