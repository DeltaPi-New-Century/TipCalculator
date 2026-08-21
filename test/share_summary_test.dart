import 'package:flutter_test/flutter_test.dart';
import 'package:tip_calculator/schemas/person.dart';
import 'package:tip_calculator/service/share_summary.dart';

void main() {
  String build({
    final int people = 1,
    final double totalPerPerson = 0,
    final List<Person> persons = const [],
  }) => ShareSummary.build(
    title: 'Tip Calculator',
    billLabel: 'Bill',
    tipLabel: 'Tip',
    totalLabel: 'Total',
    peopleLabel: 'people',
    perPersonLabel: 'Per Person',
    currencySymbol: '\$',
    amount: 100.00,
    tip: 18.00,
    tipPercent: 18,
    total: 118.00,
    people: people,
    totalPerPerson: totalPerPerson,
    persons: persons,
  );

  test('an even split lists the headline figures', () {
    final text = build(people: 4, totalPerPerson: 29.50);
    expect(text, contains('Bill: \$ 100.00'));
    expect(text, contains('Tip (18%): \$ 18.00'));
    expect(text, contains('Total: \$ 118.00'));
    expect(text, contains('4 people'));
    expect(text, contains('Per Person: \$ 29.50'));
  });

  test('a single diner gets no per-person line', () {
    final text = build(people: 1);
    expect(text, isNot(contains('Per Person')));
    expect(text, isNot(contains('1 people')));
  });

  test('an itemized split lists each person, tip included', () {
    final persons = [
      Person(
        id: 'a',
        name: 'Ana',
        items: [PersonItem(id: '1', label: 'Steak', price: 60.00)],
      ),
      Person(
        id: 'b',
        name: 'Bruno',
        items: [PersonItem(id: '2', label: 'Salad', price: 40.00)],
      ),
    ];
    final text = build(people: 2, persons: persons);

    // 60% of a $18 tip is $10.80, so Ana owes 60 + 10.80.
    expect(text, contains('\$ 70.80'));
    expect(text, contains('\$ 47.20'));
    expect(text, contains('Ana'));
    expect(text, contains('Bruno'));
    // The generic per-person line is replaced by the breakdown.
    expect(text, isNot(contains('Per Person')));
  });

  test('the money column stays aligned', () {
    final persons = [
      Person(id: 'a', name: 'Al', items: [PersonItem(id: '1', label: 'x', price: 10)]),
      Person(
        id: 'b',
        name: 'Bartholomew',
        items: [PersonItem(id: '2', label: 'y', price: 10)],
      ),
    ];
    final lines = build(people: 2, persons: persons).split('\n');
    final moneyLines = lines.where((line) => line.contains('\$')).toList();
    final offsets = moneyLines
        .map((line) => line.indexOf('\$'))
        .toSet();
    // Header lines put the symbol after a label, so only compare the
    // person rows: they must share one column.
    final personOffsets = moneyLines
        .where((line) => line.startsWith('Al') || line.startsWith('Bartholomew'))
        .map((line) => line.indexOf('\$'))
        .toSet();
    expect(personOffsets.length, 1);
    expect(offsets, isNotEmpty);
  });

  test('an over-long name is truncated rather than pushing the column', () {
    final persons = [
      Person(
        id: 'a',
        name: 'Maximiliano Bartholomew III',
        items: [PersonItem(id: '1', label: 'x', price: 100)],
      ),
    ];
    final text = build(people: 1, persons: persons);
    final row = text
        .split('\n')
        .firstWhere((line) => line.startsWith('Maximiliano'));
    expect(row.indexOf('\$'), 16);
  });

  test('a zero bill splits the tip evenly instead of dividing by zero', () {
    final persons = [
      Person(id: 'a', name: 'Ana'),
      Person(id: 'b', name: 'Bruno'),
    ];
    final text = build(people: 2, persons: persons);
    expect(text, contains('\$ 9.00'));
    expect(text, isNot(contains('NaN')));
    expect(text, isNot(contains('Infinity')));
  });
}
