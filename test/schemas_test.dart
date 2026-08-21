import 'package:flutter_test/flutter_test.dart';
import 'package:tip_calculator/schemas/person.dart';
import 'package:tip_calculator/schemas/history_entry.dart';

void main() {
  group('Person', () {
    test('subtotal sums item prices', () {
      final person = Person(
        id: 'p1',
        name: 'Ana',
        items: [
          PersonItem(id: 'i1', label: 'Steak', price: 20.00),
          PersonItem(id: 'i2', label: 'Wine', price: 5.50),
        ],
      );
      expect(person.subtotal, 25.50);
    });

    test('subtotal is zero with no items', () {
      expect(Person(id: 'p1', name: 'Ana').subtotal, 0.00);
    });

    test('survives a JSON round-trip', () {
      final original = Person(
        id: 'p1',
        name: 'Ana',
        items: [PersonItem(id: 'i1', label: 'Steak', price: 20.00)],
      );
      final restored = Person.fromJson(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.name, 'Ana');
      expect(restored.items.length, 1);
      expect(restored.subtotal, 20.00);
    });

    test('returns null on malformed JSON', () {
      expect(Person.fromJson({'nonsense': true}), isNull);
    });
  });

  group('HistoryEntry', () {
    HistoryEntry buildEntry({final List<Person>? persons}) => HistoryEntry(
      id: 'h1',
      date: DateTime(2026, 3, 14, 20, 30),
      amount: 100.00,
      people: 4,
      tipPercent: 10,
      currencySymbol: '€',
      persons: persons,
    );

    test('derives tip and totals', () {
      final entry = buildEntry();
      expect(entry.tip, 10.00);
      expect(entry.total, 110.00);
      expect(entry.totalPerPerson, 27.50);
      expect(entry.tipPerson, 2.50);
    });

    test('guards against a zero head count', () {
      final entry = HistoryEntry(
        id: 'h1',
        date: DateTime(2026, 3, 14),
        amount: 100.00,
        people: 0,
        tipPercent: 10,
        currencySymbol: '€',
      );
      expect(entry.totalPerPerson, 0.00);
      expect(entry.tipPerson, 0.00);
    });

    test('survives a JSON round-trip with a breakdown', () {
      final entry = buildEntry(
        persons: [
          Person(
            id: 'p1',
            name: 'Ana',
            items: [PersonItem(id: 'i1', label: 'Steak', price: 60.00)],
          ),
        ],
      );
      final restored = HistoryEntry.fromJson(entry.toJson());
      expect(restored, isNotNull);
      expect(restored!.isSplitByItems, isTrue);
      expect(restored.persons.single.subtotal, 60.00);
      expect(restored.date, entry.date);
    });

    test('reads entries saved before item-splitting existed', () {
      final legacy = {
        'id': 'h0',
        'date': DateTime(2026, 1, 1).toIso8601String(),
        'amount': 50.0,
        'people': 2,
        'tipPercent': 10,
        'currencySymbol': '\$',
      };
      final restored = HistoryEntry.fromJson(legacy);
      expect(restored, isNotNull);
      expect(restored!.isSplitByItems, isFalse);
      expect(restored.total, 55.00);
    });
  });
}
