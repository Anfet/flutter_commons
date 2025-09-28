import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:google_huawei_availability/google_huawei_availability.dart';
import '../app_publisher.dart';

Future<AppPublisher> resolveStore() async {
  if (kIsWeb) {
    return AppPublisher.web;
  }

  if (Platform.isIOS) {
    return AppPublisher.ios;
  }

  final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
  if (availability == GooglePlayServicesAvailability.success) {
    return AppPublisher.google;
  }

  var isHuawei = await GoogleHuaweiAvailability.isHuaweiServiceAvailable ?? false;
  if (isHuawei) {
    return AppPublisher.huawei;
  }

  return AppPublisher.other;
}
