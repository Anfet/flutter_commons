import 'dart:io';

import 'package:flutter_commons/src/data/app_store/app_store.dart';
import 'package:google_api_availability/google_api_availability.dart';

Future<AppStore> resolveStore() async {
  if (Platform.isIOS) {
    return AppStore.ios;
  }

  final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
  if (availability == GooglePlayServicesAvailability.success) {
    return AppStore.google;
  }

  // var isHuawei = await GoogleHuaweiAvailability.isHuaweiServiceAvailable ?? false;
  // if (isHuawei) {
  //   return AppStore.huawei;
  // }

  return AppStore.other;
}
