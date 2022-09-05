import 'package:flutter/widgets.dart';
import 'package:siberian_core/siberian_core.dart';

import '../localizations/localizations.dart';

class Languages {
  Languages._();

  static ChangeNotifier languageChangeNotifier = ChangeNotifier();

  static const ruRU = Locale("ru", "RU");
  static const enUS = Locale('en', 'US');
  static const roRO = Locale('ro', 'RO');

  static final List<Locale> _supportedLocales = [
    enUS,
  ];

  static Locale _locale = enUS;

  static Locale get locale => _locale;

  static set locale(Locale value) {
    if (!_supportedLocales.contains(value)) {
      throw LocaleNotSupportedException("Locale $value not supported");
    }

    _locale = value;
    languageChangeNotifier.notifyListeners();
  }

  static List<Locale> get supportedLocales => _supportedLocales;

  static void addSupportedLocales(Iterable<Locale> locales) => _supportedLocales.addAll(locales);
}
