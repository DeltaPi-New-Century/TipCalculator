import 'package:flutter_test/flutter_test.dart';
import 'package:tip_calculator/schemas/session.dart';
import 'package:tip_calculator/service/session_code.dart';

void main() {
  group('SessionCode', () {
    test('generates a code of the right shape', () {
      for (int i = 0; i < 200; i++) {
        final code = SessionCode.generate();
        expect(code.length, SessionCode.length);
        expect(SessionCode.isValid(code), isTrue);
      }
    });

    test('never emits a character people confuse when reading aloud', () {
      for (int i = 0; i < 500; i++) {
        expect(SessionCode.generate(), isNot(matches(r'[01OILU]')));
      }
    });

    test('generates varied codes', () {
      final codes = List.generate(200, (_) => SessionCode.generate()).toSet();
      // Collisions at 729M combinations should not appear in 200 draws.
      expect(codes.length, 200);
    });

    test('normalizes case and separators without changing the code', () {
      expect(SessionCode.normalize('k7qm2x'), 'K7QM2X');
      expect(SessionCode.normalize('K7QM-2X'), 'K7QM2X');
      expect(SessionCode.normalize(' K7QM 2X '), 'K7QM2X');
    });

    test('accepts a valid code however it was typed', () {
      expect(SessionCode.isValid('k7qm2x'), isTrue);
      expect(SessionCode.isValid('K7QM-2X'), isTrue);
    });

    test('rejects wrong lengths', () {
      expect(SessionCode.isValid('K7QM2'), isFalse);
      expect(SessionCode.isValid('K7QM2XY'), isFalse);
      expect(SessionCode.isValid(''), isFalse);
    });

    test('rejects confusable characters rather than guessing', () {
      // O could be Q or D; silently rewriting it could join the wrong table.
      expect(SessionCode.isValid('K7QM2O'), isFalse);
      expect(SessionCode.isValid('K7QM21'), isFalse);
      expect(SessionCode.hasConfusableCharacter('K7QM2O'), isTrue);
      expect(SessionCode.hasConfusableCharacter('K7QM2X'), isFalse);
    });

    test('the keyspace is large enough to be worth stating', () {
      expect(SessionCode.keyspace, greaterThan(700000000));
    });
  });

  group('Session.fromSnapshot', () {
    // Relative to now, never a hardcoded calendar date: a fixed "future"
    // timestamp silently becomes the past and the expiry test starts failing
    // on an unrelated day.
    Map<String, dynamic> raw({
      final String status = 'open',
      final int? expiresAt,
    }) => {
      'status': status,
      'ownerUid': 'owner1',
      'createdAt': DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch,
      'expiresAt':
          expiresAt ??
          DateTime.now().add(const Duration(hours: 23)).millisecondsSinceEpoch,
      'currency': '\$',
      'tipPercent': 18,
      'members': {
        'owner1': {'name': 'Ana', 'joinedAt': 1},
        'guest2': {'name': 'Bruno', 'joinedAt': 2},
      },
      'items': {
        'i1': {'uid': 'owner1', 'label': 'Steak', 'price': 60.0},
        'i2': {'uid': 'guest2', 'label': 'Salad', 'price': 40.0},
      },
    };

    test('parses a well-formed node', () {
      final session = Session.fromSnapshot('K7QM2X', raw());
      expect(session, isNotNull);
      expect(session!.isOpen, isTrue);
      expect(session.members.length, 2);
      expect(session.items.length, 2);
      expect(session.tipPercent, 18);
    });

    test('returns null for junk rather than a half-built session', () {
      expect(Session.fromSnapshot('K7QM2X', null), isNull);
      expect(Session.fromSnapshot('K7QM2X', 'nonsense'), isNull);
      expect(Session.fromSnapshot('K7QM2X', {'status': 'open'}), isNull);
    });

    test('orders members by join time, so the host is first', () {
      final session = Session.fromSnapshot('K7QM2X', raw())!;
      expect(session.members.first.name, 'Ana');
    });

    test('drops items with no owner or an unusable price', () {
      final broken = raw();
      broken['items'] = {
        'good': {'uid': 'owner1', 'label': 'Steak', 'price': 60.0},
        'noUid': {'label': 'Ghost', 'price': 10.0},
        'badPrice': {'uid': 'owner1', 'label': 'Weird', 'price': 'free'},
      };
      final session = Session.fromSnapshot('K7QM2X', broken)!;
      expect(session.items.length, 1);
      expect(session.items.single.label, 'Steak');
    });

    test('knows who owns it', () {
      final session = Session.fromSnapshot('K7QM2X', raw())!;
      expect(session.isOwnedBy('owner1'), isTrue);
      expect(session.isOwnedBy('guest2'), isFalse);
      expect(session.isOwnedBy(null), isFalse);
    });

    test('detects expiry', () {
      final expired = Session.fromSnapshot(
        'K7QM2X',
        raw(expiresAt: DateTime(2020, 1, 1).millisecondsSinceEpoch),
      )!;
      expect(expired.isExpired, isTrue);
      expect(Session.fromSnapshot('K7QM2X', raw())!.isExpired, isFalse);
    });
  });

  group('Session.toPersons', () {
    test('maps onto the calculator model with items attached', () {
      final session = Session.fromSnapshot('K7QM2X', {
        'status': 'open',
        'ownerUid': 'owner1',
        'createdAt': 1,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 23))
            .millisecondsSinceEpoch,
        'currency': '\$',
        'tipPercent': 18,
        'members': {
          'owner1': {'name': 'Ana', 'joinedAt': 1},
          'guest2': {'name': 'Bruno', 'joinedAt': 2},
        },
        'items': {
          'i1': {'uid': 'owner1', 'label': 'Steak', 'price': 60.0},
          'i2': {'uid': 'guest2', 'label': 'Salad', 'price': 40.0},
        },
      })!;

      final persons = session.toPersons();
      expect(persons.length, 2);
      expect(persons.first.name, 'Ana');
      expect(persons.first.subtotal, 60.00);
      expect(persons.last.subtotal, 40.00);
    });

    test('keeps a member who has not ordered yet', () {
      final session = Session.fromSnapshot('K7QM2X', {
        'status': 'open',
        'ownerUid': 'owner1',
        'createdAt': 1,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 23))
            .millisecondsSinceEpoch,
        'currency': '\$',
        'tipPercent': 18,
        'members': {
          'owner1': {'name': 'Ana', 'joinedAt': 1},
          'guest2': {'name': 'Bruno', 'joinedAt': 2},
        },
        'items': {
          'i1': {'uid': 'owner1', 'label': 'Steak', 'price': 60.0},
        },
      })!;

      final persons = session.toPersons();
      expect(persons.length, 2);
      expect(persons.last.name, 'Bruno');
      expect(persons.last.subtotal, 0.00);
    });
  });
}
