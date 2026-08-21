/// A tipping norm for a country, as a percentage range.
///
/// Holds integers rather than strings: the old version parsed "18%" with
/// `int.parse` at every read, which threw whenever the model returned anything
/// unexpected. The values now arrive already typed, via a response schema, and
/// are clamped on the way in.
class TipAdvice {
  final int minVal;
  final int avgVal;
  final int maxVal;

  const TipAdvice({
    required this.minVal,
    required this.avgVal,
    required this.maxVal,
  });

  /// Builds from decoded JSON, or returns null if it is not usable.
  ///
  /// A tip percentage outside 0-100 is a bad answer, not a value to display,
  /// so it is rejected rather than clamped into something plausible-looking.
  static TipAdvice? fromJson(final Map<String, dynamic> json) {
    int? asInt(final Object? value) {
      if (value is num) return value.round();
      if (value is String) {
        return int.tryParse(value.replaceAll('%', '').trim());
      }
      return null;
    }

    final min = asInt(json['min']);
    final avg = asInt(json['avg']);
    final max = asInt(json['max']);
    if (min == null || avg == null || max == null) return null;

    final inRange = [min, avg, max].every((value) => value >= 0 && value <= 100);
    if (!inRange) return null;
    if (min > avg || avg > max) return null;

    return TipAdvice(minVal: min, avgVal: avg, maxVal: max);
  }

  /// Short human-readable form, e.g. "15-20% is customary, 18% typical".
  String message(final String template) => template
      .replaceAll('\$min', '$minVal')
      .replaceAll('\$avg', '$avgVal')
      .replaceAll('\$max', '$maxVal');
}
