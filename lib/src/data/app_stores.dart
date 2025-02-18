import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

enum AppStores {
  unknown,
  ios,
  google,
  rustore,
  huawei,
  other,
  web,
  ;

  bool get isPublished => require(publishedUrls[this]).isNotEmpty;

  static const storeParamName = 'STORE';
  static const storeUrlParamName = 'STORE_URL';

  static AppStores _publishedStore = AppStores.unknown;

  static AppStores get publishedStore => _publishedStore;

  static String _publishedStoreUrl = '';

  static String get publishedStoreUrl => _publishedStoreUrl;

  static final Map<AppStores, String> publishedUrls = {
    AppStores.unknown: '',
    AppStores.ios: '',
    AppStores.google: '',
    AppStores.rustore: '',
    AppStores.huawei: '',
    AppStores.other: '',
    AppStores.web: '',
  };

  static void loadFromEnviroment() {
    if (const bool.hasEnvironment(storeParamName)) {
      var text = const String.fromEnvironment(storeParamName, defaultValue: 'unknown');
      _publishedStore = AppStores.values.byName(text);
    } else {
      _publishedStore = kIsWeb
          ? web
          : Platform.isIOS
              ? AppStores.ios
              : AppStores.google;
    }

    if (const bool.hasEnvironment(storeUrlParamName)) {
      _publishedStoreUrl = const String.fromEnvironment(storeUrlParamName, defaultValue: '');
    }

    logMessage("Build for '$publishedStore'", level: Level.info, tag: 'AppStore');
  }
}
