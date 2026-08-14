import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tip_calculator/service/translations_defaults.dart';

/// Translations shipped inside the app bundle.
///
/// The remote database is authoritative when it is current, but it lags: a
/// release adds UI strings before the gist is updated, and until then a
/// Spanish user would see the new labels in English while the old ones stayed
/// Spanish. Bundling the full set means the worst case is *stale* wording, not
/// a screen in two languages at once.
///
/// Resolution order, lowest priority first:
///   1. [kDefaultTranslations] -- English, guarantees no key is ever missing.
///   2. this asset, for the user's language.
///   3. the remote database, which can still correct or extend anything.
class BundledTranslations {
  const BundledTranslations._();

  static const String _assetPath = 'resources/tipcalculator_languages.json';

  static Map<String, Map<String, String>>? _cache;

  /// Parses the asset once per process.
  static Future<Map<String, Map<String, String>>> _all() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, Map<String, String>>{};
    for (final language in (decoded['languages'] as List)) {
      final code = language['code'].toString().toLowerCase();
      final translations = <String, String>{};
      for (final element in (language['elements'] as List)) {
        final entry = (element as Map).entries.first;
        translations[entry.key.toString()] = entry.value.toString();
      }
      result[code] = translations;
    }
    _cache = result;
    return result;
  }

  /// Full translation set for [languageCode], English-backed.
  ///
  /// Never throws: a missing or malformed asset degrades to the built-in
  /// English defaults rather than taking the app down.
  static Future<Map<String, String>> forLanguage(
    final String languageCode,
  ) async {
    final merged = Map<String, String>.from(kDefaultTranslations);
    try {
      final all = await _all();
      final code = languageCode.toLowerCase();
      final exact = all[code] ?? all[code.split('-').first];
      if (exact != null) merged.addAll(exact);
    } catch (_) {
      // Fall through with the English defaults.
    }
    return merged;
  }
}
