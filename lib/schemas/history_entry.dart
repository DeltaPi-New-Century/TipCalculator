import 'package:tip_calculator/schemas/person.dart';

/// A single saved tip calculation.
///
/// Stored as JSON in shared_preferences, so every field must survive a
/// round-trip through [toJson]/[fromJson].
class HistoryEntry {
  final String id;
  final DateTime date;
  final double amount;
  final int people;
  final int tipPercent;
  final String currencySymbol;
  final String? label;

  /// Populated only for bills split by items. Empty means an even split.
  final List<Person> persons;

  HistoryEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.people,
    required this.tipPercent,
    required this.currencySymbol,
    this.label,
    final List<Person>? persons,
  }) : persons = persons ?? [];

  bool get isSplitByItems => persons.isNotEmpty;

  double get tip => amount * (tipPercent / 100);
  double get total => amount + tip;
  double get totalPerPerson => (people > 0) ? total / people : 0.00;
  double get tipPerson => (people > 0) ? tip / people : 0.00;

  Map<String, dynamic> toJson() => {
    "id": id,
    "date": date.toIso8601String(),
    "amount": amount,
    "people": people,
    "tipPercent": tipPercent,
    "currencySymbol": currencySymbol,
    "label": label,
    "persons": persons.map((person) => person.toJson()).toList(),
  };

  /// Returns null when [json] is malformed, so one corrupt entry cannot break
  /// the whole history list.
  static HistoryEntry? fromJson(final Map<String, dynamic> json) {
    try {
      if (json["id"] == null) return null;
      return HistoryEntry(
        id: json["id"].toString(),
        date: DateTime.parse(json["date"].toString()),
        amount: (json["amount"] as num).toDouble(),
        people: (json["people"] as num).toInt(),
        tipPercent: (json["tipPercent"] as num).toInt(),
        currencySymbol: json["currencySymbol"]?.toString() ?? "\$",
        label: json["label"]?.toString(),
        // Absent on entries saved before item-splitting existed.
        persons: ((json["persons"] as List?) ?? [])
            .map((person) => Person.fromJson(person as Map<String, dynamic>))
            .whereType<Person>()
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
