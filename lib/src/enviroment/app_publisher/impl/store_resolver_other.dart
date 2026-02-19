import 'dart:io';

import 'package:flutter/foundation.dart';
import '../app_publisher.dart';

Future<AppPublisher> resolveStore() async {
  if (kIsWeb) {
    return AppPublisher.web;
  }

  if (Platform.isIOS) {
    return AppPublisher.ios;
  }

  return AppPublisher.google;
}
