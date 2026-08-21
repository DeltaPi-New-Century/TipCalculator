import 'package:tip_calculator/schemas/person.dart';

/// Builds the plain-text bill summary.
///
/// Text rather than an image is the primary format on purpose: it is
/// copy-pasteable, searchable in a chat history, readable by screen readers,
/// and a few hundred bytes instead of a few hundred kilobytes. The image
/// exists for people who want something that looks like a receipt.
///
/// Kept free of Flutter and plugin imports so the formatting can be tested
/// directly.
class ShareSummary {
  const ShareSummary._();

  /// Column width for the name side of an itemized line.
  static const int _nameWidth = 16;

  static String build({
    required final String title,
    required final String billLabel,
    required final String tipLabel,
    required final String totalLabel,
    required final String peopleLabel,
    required final String perPersonLabel,
    required final String currencySymbol,
    required final double amount,
    required final double tip,
    required final int tipPercent,
    required final double total,
    required final int people,
    required final double totalPerPerson,
    final List<Person> persons = const [],
  }) {
    final buffer = StringBuffer();
    String money(final double value) =>
        '$currencySymbol ${value.toStringAsFixed(2)}';

    buffer.writeln(title);
    buffer.writeln('$billLabel: ${money(amount)}');
    buffer.writeln('$tipLabel ($tipPercent%): ${money(tip)}');
    buffer.writeln('$totalLabel: ${money(total)}');

    if (persons.isNotEmpty) {
      buffer.writeln();
      for (final person in persons) {
        final name = _pad(person.name, _nameWidth);
        final share = _shareFor(person, persons, tip);
        buffer.writeln('$name${money(person.subtotal + share)}');
      }
    } else if (people > 1) {
      buffer.writeln('$people $peopleLabel');
      buffer.writeln('$perPersonLabel: ${money(totalPerPerson)}');
    }

    return buffer.toString().trimRight();
  }

  /// Tip apportioned by consumption, matching what the app displays.
  static double _shareFor(
    final Person person,
    final List<Person> persons,
    final double tip,
  ) {
    final bill = persons.fold<double>(0, (sum, item) => sum + item.subtotal);
    if (bill <= 0) return persons.isEmpty ? 0 : tip / persons.length;
    return tip * (person.subtotal / bill);
  }

  /// Right-pads to [width], truncating long names so the money column stays
  /// aligned in a monospace chat font.
  static String _pad(final String value, final int width) {
    final name = value.trim();
    if (name.length >= width) return '${name.substring(0, width - 1)} ';
    return name.padRight(width);
  }
}
