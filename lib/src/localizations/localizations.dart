import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:siberian_core/siberian_core.dart';
import 'package:sprintf/sprintf.dart';

typedef PluralSpecResolver = PluralSpec Function(int amount);
typedef TextResolver<T> = String? Function(T resId);
typedef PluralResolver<P> = Plural? Function(P resId);

class Translator<D, P> extends ChangeNotifier {
  static const ok = "OK";

  Locale _currentLocale;
  final Map<Locale, Translation<D, P>> _translations = {};

  Translator(this._currentLocale);

  get supportedLocales => _translations.values.map((tr) => tr.locale);

  get locale => _currentLocale;

  addTranslation(Translation<D, P> translation) {
    _translations.putIfAbsent(translation.locale, () => translation);
  }

  setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }

  String getString(D resId) {
    final translations = _translations[locale];
    final text = translations?.textResolver(resId);
    if (text == null) {
      throw LocalizationNotProvidedException(
          "No string provided for locale ${_currentLocale.languageCode} text $resId");
    }
    return text;
  }

  String formatString(D resId, args) {
    var text = getString(resId);
    return sprintf(text, ((args is List) ? args : [args]));
  }

  String getQuantityString(P resId, int amount) {
    Translation<D, P> translation = _translations[_currentLocale]!;
    Plural? plural = translation.pluralResolver(resId);
    if (plural == null) {
      throw QuantityLocalizationNotProvidedException(
          "No quantity string provided for ${_currentLocale.languageCode} plural $resId");
    }

    PluralSpec spec = translation.specResolver(amount);
    String format = plural.get(spec);

    if (format.isEmpty) {
      throw QuantityLocalizationNotProvidedException(
          "No quantity string provided for locale ${_currentLocale.languageCode} plural $resId");
    }

    return sprintf(format, [amount]);
  }
}

class Translation<D, P> {
  final Locale locale;
  final TextResolver<D> textResolver;
  final PluralResolver<P> pluralResolver;
  final PluralSpecResolver specResolver;

  const Translation({
    required this.locale,
    required this.textResolver,
    required this.pluralResolver,
    required this.specResolver,
  });
}

enum PluralSpec { zero, one, two, many, other }

class Plural {
  //все что заканчивается на 0. (0, 10, 20)
  final String zero;

  //заканчивающиееся на 1
  final String one;

  //заканчивающиееся на 2
  final String two;

  //множественное кол-во
  final String many;

  //что не попадает во все остальное
  final String other;

  const Plural({
    required this.zero,
    required this.one,
    required this.two,
    required this.many,
    required this.other,
  });

  String get(PluralSpec spec) {
    switch (spec) {
      case PluralSpec.zero:
        return zero;
      case PluralSpec.one:
        return one;
      case PluralSpec.two:
        return two;
      case PluralSpec.many:
        return many;
      default:
        return other;
    }
  }
}

class LocalizationException extends AppException {
  LocalizationException(String message) : super(message);
}

class LocalizationNotProvidedException extends LocalizationException {
  LocalizationNotProvidedException(String message) : super(message);
}

class QuantityLocalizationNotProvidedException extends LocalizationException {
  QuantityLocalizationNotProvidedException(String message) : super(message);
}

class LocaleNotSupportedException extends LocalizationException {
  LocaleNotSupportedException(String message) : super(message);
}
