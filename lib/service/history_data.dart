import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tip_calculator/schemas/person.dart';
import 'package:tip_calculator/schemas/history_entry.dart';

/// Persists saved tip calculations in shared_preferences.
///
/// Entries are kept newest-first and capped at [_maxEntries]; this is a tip
/// calculator, not a ledger, so unbounded growth buys nothing.
class HistoryData with ChangeNotifier {
  static const String _storageKey = "tip_history";
  static const int _maxEntries = 100;

  List<HistoryEntry> _entries = [];
  bool _loaded = false;

  HistoryData() {
    _load();
  }

  List<HistoryEntry> get entries => List.unmodifiable(_entries);
  bool get isEmpty => _entries.isEmpty;
  bool get isLoaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _entries = raw
        .map((item) {
          try {
            return HistoryEntry.fromJson(jsonDecode(item));
          } catch (_) {
            return null;
          }
        })
        .whereType<HistoryEntry>()
        .toList();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> add({
    required final double amount,
    required final int people,
    required final int tipPercent,
    required final String currencySymbol,
    final String? label,
    final List<Person>? persons,
  }) async {
    final entry = HistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: amount,
      people: people,
      tipPercent: tipPercent,
      currencySymbol: currencySymbol,
      label: label,
      persons: persons,
    );
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(final String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
    await _persist();
  }

  /// Re-inserts [entry] at [index], used to undo a swipe-delete.
  Future<void> restore(final HistoryEntry entry, final int index) async {
    _entries.insert(index.clamp(0, _entries.length), entry);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _entries = [];
    notifyListeners();
    await _persist();
  }
}
