import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tip_calculator/schemas/person.dart';
import 'package:tip_calculator/service/history_data.dart';

/// Saving a session's bill to history reported success but nothing appeared in
/// the history list. These pin down which half was at fault: the write, or the
/// round-trip back out of storage.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Shaped like a session: ids are Firebase uids, not local indices.
  List<Person> sessionPersons() => [
    Person(
      id: 'dwn8hVWqeSObk32wCRo0LfWpSRY2',
      name: 'Ezequiel',
      items: [PersonItem(id: '-Nxyz1', label: 'Pizza', price: 12.5)],
    ),
    Person(
      id: 'aB3kLmNoPqRsTuVwXyZ0123456789',
      name: 'Ana',
      items: [PersonItem(id: '-Nxyz2', label: 'Wine', price: 7.25)],
    ),
  ];

  test('a session bill is added to the in-memory list', () async {
    final history = HistoryData();
    final persons = sessionPersons();

    await history.add(
      amount: 19.75,
      people: persons.length,
      tipPercent: 10,
      currencySymbol: r'$',
      persons: persons,
    );

    expect(history.entries, hasLength(1));
    expect(history.entries.first.isSplitByItems, isTrue);
    expect(history.entries.first.persons, hasLength(2));
  });

  test('a session bill survives a reload from storage', () async {
    final history = HistoryData();
    await history.add(
      amount: 19.75,
      people: 2,
      tipPercent: 10,
      currencySymbol: r'$',
      persons: sessionPersons(),
    );

    // A second instance reads what the first persisted, which is what the
    // history screen does after the app is reopened.
    final reloaded = HistoryData();
    await Future<void>.delayed(Duration.zero);

    expect(reloaded.entries, hasLength(1));
    expect(reloaded.entries.first.amount, 19.75);
    expect(reloaded.entries.first.persons.first.items.first.label, 'Pizza');
  });
}
