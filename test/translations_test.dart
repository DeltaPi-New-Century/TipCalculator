import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tip_calculator/service/bundled_translations.dart';
import 'package:tip_calculator/service/translations_defaults.dart';

/// Guards against the commonest i18n failure here: a new UI string added to
/// the Dart defaults but never shipped to the remote database (or vice versa),
/// which leaves users of that locale looking at English or at a raw key.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final languagesFile = File('resources/tipcalculator_languages.json');

  Map<String, Map<String, String>> readLanguages() {
    final decoded = jsonDecode(languagesFile.readAsStringSync());
    final result = <String, Map<String, String>>{};
    for (final language in decoded['languages'] as List) {
      final translations = <String, String>{};
      for (final element in language['elements'] as List) {
        final entry = (element as Map).entries.first;
        translations[entry.key.toString()] = entry.value.toString();
      }
      result[language['code'].toString()] = translations;
    }
    return result;
  }

  test('languages resource exists', () {
    expect(languagesFile.existsSync(), isTrue);
  });

  test('every language covers every default key', () {
    final languages = readLanguages();
    expect(languages.keys, containsAll(<String>['en', 'es']));

    for (final entry in languages.entries) {
      final missing = kDefaultTranslations.keys
          .where((key) => !entry.value.containsKey(key))
          .toList();
      expect(missing, isEmpty, reason: '${entry.key} is missing: $missing');
    }
  });

  test('no language ships keys the app does not use', () {
    final languages = readLanguages();
    for (final entry in languages.entries) {
      final unknown = entry.value.keys
          .where((key) => !kDefaultTranslations.containsKey(key))
          .toList();
      expect(unknown, isEmpty, reason: '${entry.key} has unused: $unknown');
    }
  });

  test('english resource matches the built-in defaults exactly', () {
    expect(readLanguages()['en'], kDefaultTranslations);
  });

  test('the bundled asset is a superset of what the remote ships', () {
    // The whole point of bundling: a stale remote can only make wording older,
    // never leave a key untranslated and therefore English on a Spanish phone.
    final languages = readLanguages();
    for (final entry in languages.entries) {
      expect(
        entry.value.length,
        kDefaultTranslations.length,
        reason: '${entry.key} must cover every key the UI can ask for',
      );
    }
  });

  test('spanish is actually translated, not copied from english', () {
    final languages = readLanguages();
    final es = languages['es']!;
    final en = languages['en']!;
    // A handful of keys legitimately match ("Total"), but the bulk must differ
    // or the asset is not doing its job.
    final identical = es.keys.where((key) => es[key] == en[key]).length;
    expect(identical, lessThan(en.length ~/ 3));
  });

  group('bundled asset', () {
    test('loads from rootBundle, so pubspec declares it', () async {
      // If the asset is missing from pubspec this silently degrades to English
      // in the app; here it must fail loudly.
      final raw = await rootBundle.loadString(
        'resources/tipcalculator_languages.json',
      );
      expect(raw, isNotEmpty);
    });

    test('spanish resolves fully translated', () async {
      final es = await BundledTranslations.forLanguage('es');
      expect(es.length, kDefaultTranslations.length);
      expect(es['history_title'], 'Historial');
      expect(es['split_by_items'], 'Por consumo');
      expect(es['theme_dark'], 'Oscuro');
    });

    test('a regional code falls back to its base language', () async {
      final es = await BundledTranslations.forLanguage('es-AR');
      expect(es['history_title'], 'Historial');
    });

    test('an unknown language degrades to english, not to blanks', () async {
      final unknown = await BundledTranslations.forLanguage('zz');
      expect(unknown, kDefaultTranslations);
    });
  });

  test('no translation is left empty', () {
    for (final entry in readLanguages().entries) {
      final blank = entry.value.entries
          .where((pair) => pair.value.trim().isEmpty)
          .map((pair) => pair.key)
          .toList();
      expect(blank, isEmpty, reason: '${entry.key} has blank: $blank');
    }
  });
}
