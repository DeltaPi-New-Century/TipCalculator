/// One diner and what they consumed, used by the "split by items" mode.
class PersonItem {
  final String id;
  String label;
  double price;

  PersonItem({required this.id, required this.label, required this.price});

  Map<String, dynamic> toJson() => {"id": id, "label": label, "price": price};

  static PersonItem? fromJson(final Map<String, dynamic> json) {
    try {
      if (json["id"] == null) return null;
      return PersonItem(
        id: json["id"].toString(),
        label: json["label"]?.toString() ?? "",
        price: (json["price"] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

class Person {
  final String id;
  String name;
  final List<PersonItem> items;

  Person({required this.id, required this.name, final List<PersonItem>? items})
    : items = items ?? [];

  /// What this person consumed, before tip.
  double get subtotal =>
      items.fold(0.00, (sum, item) => sum + item.price);

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "items": items.map((item) => item.toJson()).toList(),
  };

  static Person? fromJson(final Map<String, dynamic> json) {
    try {
      // null.toString() is "null", not a throw -- without this check a
      // malformed map would quietly become a person with a bogus id.
      if (json["id"] == null) return null;
      final rawItems = (json["items"] as List?) ?? [];
      return Person(
        id: json["id"].toString(),
        name: json["name"]?.toString() ?? "",
        items: rawItems
            .map((item) => PersonItem.fromJson(item as Map<String, dynamic>))
            .whereType<PersonItem>()
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
