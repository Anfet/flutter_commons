import 'dart:io';

import 'package:flutter_commons/src/data/app_store/app_store.dart';
import 'package:flutter_commons/src/data/app_store/impl/store_resolver_stub.dart';
import 'package:google_huawei_availability/google_huawei_availability.dart';

class AppStoreResolverOther implements AppStoreResolver {
  @override
  Future<AppStore> resolve() async {
    if (Platform.isIOS) {
      return AppStore.ios;
    }

    var isGoogle = await GoogleHuaweiAvailability.isGoogleServiceAvailable ?? false;
    if (isGoogle) {
      return AppStore.google;
    }

    var isHuawei = await GoogleHuaweiAvailability.isHuaweiServiceAvailable ?? false;
    if (isHuawei) {
      return AppStore.huawei;
    }

    return AppStore.other;
  }
}
