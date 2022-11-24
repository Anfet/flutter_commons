import 'package:flutter/widgets.dart';
import 'package:siberian_core/siberian_core.dart';

import '../localizations/localizations.dart';

class Languages {
  Languages._();

  static ValueNotifier<Locale> languageChangeNotifier = ValueNotifier(enUS);

  static const ruRU = Locale("ru", "RU");
  static const enUS = Locale('en', 'US');
  static const roRO = Locale('ro', 'RO');

  static final List<Locale> _supportedLocales = [
    enUS,
  ];

  static Locale get locale => languageChangeNotifier.value;

  static set locale(Locale value) {
    if (!_supportedLocales.contains(value)) {
      throw LocaleNotSupportedException("Locale $value not supported");
    }

    languageChangeNotifier.value = value;
  }

  static List<Locale> get supportedLocales => _supportedLocales;

  static void addSupportedLocales(Iterable<Locale> locales) => _supportedLocales.addAll(locales);
}
