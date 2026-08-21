import 'dart:math';

/// Generates and validates the code that joins people to a session.
///
/// Kept free of Firebase imports so the alphabet and validation rules can be
/// tested directly -- they are the part most likely to be got wrong, and the
/// part users notice when it is.
class SessionCode {
  const SessionCode._();

  /// Deliberately missing 0/O, 1/I/L and U.
  ///
  /// This code gets read aloud across a noisy restaurant table and typed by
  /// someone who has had a glass of wine. Removing the characters people
  /// confuse when speaking or hearing them matters more than the handful of
  /// bits of entropy it costs.
  ///
  /// Because none of the confusable characters are in the alphabet, a typed
  /// "O" or "1" can only be a mistake -- and there is no honest way to guess
  /// whether the user meant Q, D or something else. Such input is rejected so
  /// the user retypes, rather than silently rewritten into a code that is
  /// valid but belongs to a different table.
  static const String alphabet = '23456789ABCDEFGHJKMNPQRSTVWXYZ';

  static const int length = 6;

  /// 30^6, about 729 million combinations.
  static int get keyspace => pow(alphabet.length, length).toInt();

  static final Random _random = Random.secure();

  /// A fresh random code.
  ///
  /// Uses [Random.secure]: a predictable generator would let someone enumerate
  /// live sessions, and the rules cannot rate-limit reads.
  static String generate() => List.generate(
    length,
    (_) => alphabet[_random.nextInt(alphabet.length)],
  ).join();

  /// Tidies what the user typed without changing which code it is.
  ///
  /// Uppercases and drops spaces and dashes, since people naturally write
  /// "k7qm 2x" or "K7QM-2X". Nothing else is substituted.
  static String normalize(final String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[\s\-_.]'), '');

  /// Whether [input] is a well-formed code.
  ///
  /// Cheap local check so an obviously wrong code never costs a round trip.
  static bool isValid(final String input) {
    final normalized = normalize(input);
    if (normalized.length != length) return false;
    return normalized.split('').every(alphabet.contains);
  }

  /// The characters a user might type that this alphabet deliberately omits,
  /// so the UI can explain the rejection instead of just refusing.
  static bool hasConfusableCharacter(final String input) =>
      normalize(input).split('').any('01OILU'.contains);
}
