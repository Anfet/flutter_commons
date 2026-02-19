import 'package:flutter_commons/flutter_commons.dart';
import 'impl/store_resolver_stub.dart'
    if (dart.library.html) './impl/store_resolver_web.dart'
    if (dart.library.io) './impl/store_resolver_other.dart';

enum AppPublisher {
  unknown,
  ios,
  google,
  rustore,
  huawei,
  other,
  web,
  ;

  String get publisherUrl => publisherUrls[this] ?? '';

  bool get isPublished => publisherUrl.isNotEmpty;

  static const storeParamName = 'STORE';
  static const publisherParamName = 'PUBLISHER';
  static const storeUrlParamName = 'STORE_URL';
  static const publisherUrlParamName = 'PUBLISHER_URL';

  static AppPublisher _publisher = AppPublisher.unknown;

  static AppPublisher get publisher => _publisher;

  static Map<AppPublisher, String> get publisherUrls => Map.unmodifiable(_publisherUrls);

  static final Map<AppPublisher, String> _publisherUrls = {
    AppPublisher.unknown: '',
    AppPublisher.ios: '',
    AppPublisher.google: '',
    AppPublisher.rustore: '',
    AppPublisher.huawei: '',
    AppPublisher.other: '',
    AppPublisher.web: '',
  };

  static void registerUrl(AppPublisher publisher, String url) {
    _publisherUrls[publisher] = url;
  }

  static Future loadFromEnviroment() async {
    if (const bool.hasEnvironment(publisherParamName)) {
      var text = const String.fromEnvironment(publisherParamName, defaultValue: 'unknown');
      _publisher = AppPublisher.values.byName(text);
    } else if (const bool.hasEnvironment(storeParamName)) {
      var text = const String.fromEnvironment(storeParamName, defaultValue: 'unknown');
      _publisher = AppPublisher.values.byName(text);
    } else {
      _publisher = await resolveStore();
    }

    if (const bool.hasEnvironment(storeUrlParamName)) {
      var publisherUrl = const String.fromEnvironment(storeUrlParamName, defaultValue: '');
      registerUrl(_publisher, publisherUrl);
    } else if (const bool.hasEnvironment(publisherUrlParamName)) {
      var publisherUrl = const String.fromEnvironment(publisherUrlParamName, defaultValue: '');
      registerUrl(_publisher, publisherUrl);
    }

    logMessage(publisher.name, tag: 'AppPublisher');
  }
}
