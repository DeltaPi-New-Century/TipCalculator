import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tip_calculator/schemas/history_entry.dart';
import 'package:tip_calculator/schemas/person.dart';
import 'package:tip_calculator/service/tip_data.dart';

/// The main-screen bill went stale during a session: items arrived through
/// [TipData.setSessionPersons], which was the one mutation that never synced
/// the derived fields. It corrected itself only when a mode switch forced a
/// resync, which is exactly how the bug was noticed.
void main() {
  // TipData reads translations and preferences from its constructor.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  List<Person> table({required final double price}) => [
    Person(
      id: 'uid-a',
      name: 'Ezequiel',
      items: [PersonItem(id: 'i1', label: 'Pizza', price: price)],
    ),
    Person(id: 'uid-b', name: 'Ana'),
  ];

  test('a session update refreshes the displayed amount', () {
    final tipData = TipData();

    tipData.setSessionPersons(table(price: 10));
    expect(tipData.amount, 10);
    expect(tipData.amountController.text, '10,00');

    // A second snapshot, as if someone added to their tab.
    tipData.setSessionPersons(table(price: 25.5));
    expect(tipData.amount, 25.5);
    expect(tipData.amountController.text, '25,50');
  });

  test('the head count follows the session, not the local table', () {
    final tipData = TipData();
    tipData.setSessionPersons(table(price: 10));

    expect(tipData.people, 2);
    expect(tipData.peopleController.text, '2');
  });

  test('a saved bill cannot be restored over a live session', () {
    final tipData = TipData();
    tipData.setSessionPersons(table(price: 10));

    final saved = HistoryEntry(
      id: '1',
      date: DateTime.now(),
      amount: 99,
      people: 4,
      tipPercent: 20,
      currencySymbol: r'$',
    );

    expect(tipData.loadFrom(saved), isFalse);
    // The live table is untouched.
    expect(tipData.amount, 10);
    expect(tipData.people, 2);
  });

  test('a saved bill loads normally with no session', () {
    final tipData = TipData();
    final saved = HistoryEntry(
      id: '1',
      date: DateTime.now(),
      amount: 99,
      people: 4,
      tipPercent: 20,
      currencySymbol: r'$',
    );

    expect(tipData.loadFrom(saved), isTrue);
    expect(tipData.amount, 99);
  });
}
