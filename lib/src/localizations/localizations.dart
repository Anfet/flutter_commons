import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siberian_core/siberian_core.dart';
import 'package:sprintf/sprintf.dart';

typedef PluralSpecResolver = PluralSpec Function(int amount);
typedef TextResolver<T> = String? Function(T resId);
typedef PluralResolver<P> = Plural? Function(P resId);

class Translator<D, P> extends ValueNotifier<Locale> {
  static const ok = "OK";

  final bool markMissingTranslations;

  final Map<String, Translation<D, P>> _translations = {};

  final Locale defaultLocale;

  Translation<D, P>? get defaultTranslations => _translations[defaultLocale.languageCode];

  Translator(Locale locale, {required this.defaultLocale, this.markMissingTranslations = false}) : super(locale);

  Iterable<Locale> get supportedLocales => _translations.values.map((tr) => tr.locale);

  Locale get locale => this.value;

  addTranslation(Translation<D, P> translation) {
    _translations.putIfAbsent(translation.locale.languageCode, () => translation);
    initializeDateFormatting(translation.locale.languageCode);
  }

  set locale(Locale locale) => value = locale;

  String getString(D resId) {
    final translations = _translations[locale.languageCode];
    var text = translations?.textResolver(resId) ??
        (
          defaultTranslations?.textResolver(resId)?.let(
            (it) {
              if (!markMissingTranslations) {
                return it;
              }
              return "$it (${locale.languageCode})";
            },
          ),
        );
    return text ?? '$resId';
  }

  String formatString(D resId, args) {
    var text = getString(resId);
    return sprintf(text, ((args is List) ? args : [args]));
  }

  String getQuantityString(P resId, int amount) {
    Translation<D, P> translation = _translations[locale.languageCode]!;
    Plural? plural = translation.pluralResolver(resId);

    var isDefault = false;
    if (plural == null) {
      plural = defaultTranslations?.pluralResolver(resId);
      isDefault = true;
      // throw QuantityLocalizationNotProvidedException("No quantity string provided for ${locale.languageCode} plural $resId");
    }

    if (plural == null) {
      if (!isDefault) {
        return '$resId(${locale.languageCode})';
      }

      return '$resId';
      // throw QuantityLocalizationNotProvidedException("No quantity string provided for ${locale.languageCode} plural $resId");
    }

    PluralSpec spec = translation.specResolver(amount);
    String format = plural.get(spec);

    if (format.isEmpty) {
      throw QuantityLocalizationNotProvidedException("No quantity string provided for locale ${locale.languageCode} plural $resId");
    }

    var result = sprintf(format, [amount]);
    if (!isDefault) {
      return "$result(${locale.languageCode})";
    }

    return result;
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
