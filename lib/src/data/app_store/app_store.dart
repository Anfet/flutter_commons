import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_commons/src/data/app_store/impl/store_resolver_stub.dart'
    if (dart.library.html) './impl/store_resolver_web.dart'
    if (dart.library.io) './impl/store_resolver_other.dart';

enum AppStore {
  unknown,
  ios,
  google,
  rustore,
  huawei,
  other,
  web,
  ;

  bool get isPublished => require(storeUrls[this]).isNotEmpty;

  static const storeParamName = 'STORE';
  static const storeUrlParamName = 'STORE_URL';

  static AppStore _publishedStore = AppStore.unknown;

  static AppStore get current => _publishedStore;

  static String _publishedStoreUrl = '';

  static String get publishedStoreUrl => _publishedStoreUrl;

  static Map<AppStore, String> get storeUrls => Map.unmodifiable(_storeUrls);

  static final Map<AppStore, String> _storeUrls = {
    AppStore.unknown: '',
    AppStore.ios: '',
    AppStore.google: '',
    AppStore.rustore: '',
    AppStore.huawei: '',
    AppStore.other: '',
    AppStore.web: '',
  };

  static void registerStoreUrl(AppStore store, String url) {
    _storeUrls[store] = url;
  }

  static Future loadFromEnviroment() async {
    if (const bool.hasEnvironment(storeParamName)) {
      var text = const String.fromEnvironment(storeParamName, defaultValue: 'unknown');
      _publishedStore = AppStore.values.byName(text);
    } else {
      _publishedStore = await resolveStore();
    }

    if (const bool.hasEnvironment(storeUrlParamName)) {
      _publishedStoreUrl = const String.fromEnvironment(storeUrlParamName, defaultValue: '');
      registerStoreUrl(_publishedStore, _publishedStoreUrl);
    }

    logMessage(current.name, level: Level.debug, tag: 'AppStore');
  }
}
