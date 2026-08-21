import 'package:flutter_test/flutter_test.dart';
import 'package:tip_calculator/service/config.dart';

/// The invite shared only the code, with no link. The join URL is built from
/// [Config.webBaseUrl], which was empty in every build that did not pass
/// --dart-define -- which was every phone build, the only place invites are
/// actually sent from.
void main() {
  test('a join url is produced by default', () {
    final url = Config.joinUrl('K7QM2X');

    expect(url, isNotNull);
    expect(url, endsWith('/?code=K7QM2X'));
    expect(url, startsWith('https://'));
  });

  test('the url carries the code as a query parameter', () {
    // Parsed rather than string-matched: this is what the web app reads back
    // out of Uri.base to prefill the field.
    final parsed = Uri.parse(Config.joinUrl('ABC234')!);

    expect(parsed.queryParameters['code'], 'ABC234');
  });
}
