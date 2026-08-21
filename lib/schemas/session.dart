import 'package:tip_calculator/schemas/person.dart';

/// A shared bill, as stored under `/sessions/{code}`.
///
/// Mirrors the security rules exactly: anything the rules reject must not be
/// constructible here either, so a malformed node from the network degrades to
/// null rather than into a half-built session on screen.
class Session {
  final String code;
  final String status;
  final String ownerUid;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String currency;
  final int tipPercent;
  final List<SessionMember> members;
  final List<SessionItem> items;

  const Session({
    required this.code,
    required this.status,
    required this.ownerUid,
    required this.createdAt,
    required this.expiresAt,
    required this.currency,
    required this.tipPercent,
    this.members = const [],
    this.items = const [],
  });

  bool get isOpen => status == 'open';
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether [uid] created this session, and may therefore close it.
  bool isOwnedBy(final String? uid) => uid != null && uid == ownerUid;

  /// Collapses members and their items into the model the calculator already
  /// uses, so every existing tip calculation works unchanged.
  ///
  /// Members with nothing ordered are kept: they are at the table, and the
  /// even-split fallback in `tipFor` gives them a sensible share until they
  /// add something.
  List<Person> toPersons() {
    return members.map((member) {
      final owned = items.where((item) => item.uid == member.uid);
      return Person(
        id: member.uid,
        name: member.name,
        items: owned
            .map(
              (item) => PersonItem(
                id: item.id,
                label: item.label,
                price: item.price,
              ),
            )
            .toList(),
      );
    }).toList();
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'ownerUid': ownerUid,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'expiresAt': expiresAt.millisecondsSinceEpoch,
    'currency': currency,
    'tipPercent': tipPercent,
  };

  static Session? fromSnapshot(
    final String code,
    final Object? value,
  ) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    try {
      final createdAt = map['createdAt'];
      final expiresAt = map['expiresAt'];
      if (createdAt is! num || expiresAt is! num) return null;
      if (map['ownerUid'] == null || map['status'] == null) return null;

      return Session(
        code: code,
        status: map['status'].toString(),
        ownerUid: map['ownerUid'].toString(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt.toInt()),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt.toInt()),
        currency: map['currency']?.toString() ?? '\$',
        tipPercent: (map['tipPercent'] as num?)?.toInt() ?? 0,
        members: _parseMembers(map['members']),
        items: _parseItems(map['items']),
      );
    } catch (_) {
      return null;
    }
  }

  static List<SessionMember> _parseMembers(final Object? raw) {
    if (raw is! Map) return const [];
    return raw.entries
        .map((entry) => SessionMember.fromEntry(entry.key.toString(), entry.value))
        .whereType<SessionMember>()
        .toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
  }

  static List<SessionItem> _parseItems(final Object? raw) {
    if (raw is! Map) return const [];
    return raw.entries
        .map((entry) => SessionItem.fromEntry(entry.key.toString(), entry.value))
        .whereType<SessionItem>()
        .toList();
  }
}

class SessionMember {
  final String uid;
  final String name;
  final DateTime joinedAt;

  const SessionMember({
    required this.uid,
    required this.name,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'joinedAt': joinedAt.millisecondsSinceEpoch,
  };

  static SessionMember? fromEntry(final String uid, final Object? value) {
    if (value is! Map) return null;
    final joinedAt = value['joinedAt'];
    if (joinedAt is! num) return null;
    return SessionMember(
      uid: uid,
      name: value['name']?.toString() ?? '',
      joinedAt: DateTime.fromMillisecondsSinceEpoch(joinedAt.toInt()),
    );
  }
}

class SessionItem {
  final String id;
  final String uid;
  final String label;
  final double price;

  const SessionItem({
    required this.id,
    required this.uid,
    required this.label,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'label': label,
    'price': price,
  };

  static SessionItem? fromEntry(final String id, final Object? value) {
    if (value is! Map) return null;
    final price = value['price'];
    final uid = value['uid'];
    // A price that is not a number, or an item with no owner, cannot be
    // rendered or attributed -- drop it rather than showing a zero-cost line.
    if (price is! num || uid == null) return null;
    return SessionItem(
      id: id,
      uid: uid.toString(),
      label: value['label']?.toString() ?? '',
      price: price.toDouble(),
    );
  }
}
