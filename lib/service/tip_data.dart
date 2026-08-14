import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tip_calculator/schemas/tip.dart';
import 'package:tip_calculator/schemas/person.dart';
import 'package:tip_calculator/schemas/history_entry.dart';
import 'package:tip_calculator/service/config.dart';
import 'package:tip_calculator/service/gemini.dart';
import 'package:tip_calculator/service/database.dart';
import 'package:tip_calculator/service/language.dart';
import 'package:tip_calculator/service/geolocation.dart';
import 'package:tip_calculator/service/translations_defaults.dart';
import 'package:tip_calculator/service/bundled_translations.dart';

/// How the bill is divided.
///
/// [evenly] splits the total by head count. [byItems] gives each person their
/// own consumption and spreads the tip in proportion to it, so the person who
/// ordered the steak pays more tip than the one who had a salad.
enum SplitMode { evenly, byItems }

class TipData with ChangeNotifier {
  DatabaseData? _databaseData;
  GeminiAPI? _geminiAPI;
  TipPorcentData? _recommendedTip;
  double _amount = 0.00;
  int _people = 1, _tipPercent = 0;
  String _actualPosition = "";
  SplitMode _splitMode = SplitMode.evenly;
  final List<Person> _persons = [];

  /// Starts as the English defaults so the very first frame is never blank,
  /// then is replaced wholesale as each layer resolves.
  Map<String, String> _translations = Map<String, String>.from(
    kDefaultTranslations,
  );

  /// Owned here so [loadFrom] can push restored values back into the fields.
  /// Widgets must not create their own -- a controller rebuilt on every build
  /// loses cursor position and leaks.
  final TextEditingController amountController = TextEditingController();
  final TextEditingController peopleController = TextEditingController(
    text: "1",
  );

  TipData() {
    _initialize();
  }

  @override
  void dispose() {
    amountController.dispose();
    peopleController.dispose();
    super.dispose();
  }

  String get countryName =>
      (_databaseData != null && _databaseData!.countryData != null)
      ? _databaseData!.countryData!.country
      : "";
  String get recommendedTip =>
      ((_recommendedTip != null) ? _recommendedTip!.message : "");
  int get tipPercent => _tipPercent;
  SplitMode get splitMode => _splitMode;
  bool get isSplitByItems => _splitMode == SplitMode.byItems;
  List<Person> get persons => List.unmodifiable(_persons);

  /// In [SplitMode.byItems] the head count and the bill are derived from the
  /// people list, so the manual amount/people fields are ignored.
  int get people => isSplitByItems ? _persons.length : _people;
  double get amount => isSplitByItems
      ? _persons.fold(0.00, (sum, person) => sum + person.subtotal)
      : _amount;

  double get tip => (amount * (_tipPercent / 100));
  double get tipPerson => ((people > 0) ? tip / people : 0.00);
  double get total => (amount + tip);
  double get totalPerPerson => ((people > 0) ? total / people : 0.00);

  /// [person]'s share of the tip, proportional to what they consumed.
  /// Falls back to an even split when the bill is zero, so a table of
  /// not-yet-filled-in people still shows sane numbers.
  double tipFor(final Person person) {
    if (amount <= 0) {
      return (_persons.isEmpty) ? 0.00 : tip / _persons.length;
    }
    return tip * (person.subtotal / amount);
  }

  double totalFor(final Person person) => person.subtotal + tipFor(person);
  String get currencySymbol =>
      (_databaseData != null && _databaseData!.countryData != null)
      ? _databaseData!.countryData!.currency.symbol
      : "\$";
  String get currencyName =>
      (_databaseData != null && _databaseData!.countryData != null)
      ? _databaseData!.countryData!.currency.name
      : "USD";
  /// The resolved translation set: English defaults, overlaid with the
  /// bundled asset for the user's language, overlaid with the remote database.
  ///
  /// Built once in [_initialize] rather than merged per lookup -- a stale
  /// remote must not be able to leave one screen in Spanish and the next in
  /// English, which is what happens when each key falls back independently.
  Map<String, String> get translations => _translations;

  /// Translated string for [key].
  ///
  /// Returns [key] itself if it is unknown everywhere, which makes a missing
  /// translation obvious instead of blank.
  String t(final String key) => _translations[key] ?? key;

  Future<void> _initialize() async {
    // Geolocation and the remote database both go over the network, and the
    // temp directory needs a platform plugin. Any of them can fail; none of
    // them should take the app down -- the calculator works offline with the
    // built-in defaults.
    final langCode = Language.getLanguageCode();

    // Layer 2: the bundled asset. Loaded first and independently of the
    // network so the UI is fully translated even when everything below fails.
    _translations = await BundledTranslations.forLanguage(langCode);
    notifyListeners();

    try {
      final dir = await getTemporaryDirectory();
      final dbLocal = '${dir.path}/database.json';
      _actualPosition = await Geolocation.getCurrentLocation("country");
      _databaseData = await DatabaseData.loadDatabase(
        Config.DB_PATH,
        dbLocal,
        _actualPosition,
        langCode,
      );
      // Layer 3: the remote database corrects or extends the bundle.
      final remote = _databaseData?.languageData?.translations;
      if (remote != null && remote.isNotEmpty) {
        _translations = {..._translations, ...remote};
      }
      _geminiAPI = GeminiAPI(
        apiUrl: Config.GEMINI_API_URL,
        apiKey: Config.GEMINI_API_KEY,
      );
    } catch (error) {
      debugPrint('TipData initialization failed, using defaults: $error');
    }
    notifyListeners();
  }

  void setAmount(double newAmount) {
    _amount = newAmount;
    notifyListeners();
  }

  void setPeople(int newPeople) {
    _people = newPeople < 1 ? 1 : newPeople;
    peopleController.text = _people.toString();
    notifyListeners();
  }

  void incrementPeople() => setPeople(_people + 1);
  void decrementPeople() => setPeople(_people - 1);

  void setTipPercent(int newPercent) {
    _tipPercent = newPercent.clamp(0, 100);
    notifyListeners();
  }

  void setSplitMode(final SplitMode mode) {
    if (_splitMode == mode) return;
    _splitMode = mode;
    // Entering item mode with nobody listed leaves the user staring at an
    // empty screen; seed it from the head count they already typed.
    if (mode == SplitMode.byItems) {
      if (_persons.isEmpty) {
        final seed = _people > 0 ? _people : 1;
        for (int index = 0; index < seed; index++) {
          _persons.add(_newPerson(index));
        }
      }
      _syncDerivedFields();
    } else {
      // Carry the item-mode figures over so switching back does not throw
      // away what the user just entered.
      if (_persons.isNotEmpty) {
        _amount = _persons.fold(0.00, (sum, person) => sum + person.subtotal);
        _people = _persons.length;
        amountController.text = _amount.toStringAsFixed(2).replaceAll('.', ',');
        peopleController.text = _people.toString();
      }
    }
    notifyListeners();
  }

  Person _newPerson(final int index) => Person(
    id: '${DateTime.now().microsecondsSinceEpoch}_$index',
    name: '${t('person')} ${index + 1}',
  );

  void addPerson() {
    _persons.add(_newPerson(_persons.length));
    _syncDerivedFields();
    notifyListeners();
  }

  void removePerson(final String personId) {
    _persons.removeWhere((person) => person.id == personId);
    _syncDerivedFields();
    notifyListeners();
  }

  void renamePerson(final String personId, final String name) {
    final person = _findPerson(personId);
    if (person == null) return;
    person.name = name;
    notifyListeners();
  }

  void addItem(
    final String personId,
    final String label,
    final double price,
  ) {
    final person = _findPerson(personId);
    if (person == null) return;
    person.items.add(
      PersonItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        price: price,
      ),
    );
    _syncDerivedFields();
    notifyListeners();
  }

  void removeItem(final String personId, final String itemId) {
    final person = _findPerson(personId);
    if (person == null) return;
    person.items.removeWhere((item) => item.id == itemId);
    _syncDerivedFields();
    notifyListeners();
  }

  void clearPersons() {
    _persons.clear();
    _syncDerivedFields();
    notifyListeners();
  }

  /// Mirrors the derived bill/head count into the (disabled) main-screen
  /// fields so item mode does not leave stale numbers on display.
  void _syncDerivedFields() {
    if (!isSplitByItems) return;
    amountController.text = amount.toStringAsFixed(2).replaceAll('.', ',');
    peopleController.text = _persons.length.toString();
  }

  Person? _findPerson(final String personId) {
    for (final person in _persons) {
      if (person.id == personId) return person;
    }
    return null;
  }

  /// Loads a saved calculation back into the calculator, text fields included.
  void loadFrom(final HistoryEntry entry) {
    _amount = entry.amount;
    _people = entry.people;
    _tipPercent = entry.tipPercent;
    amountController.text = entry.amount.toStringAsFixed(2).replaceAll(
      '.',
      ',',
    );
    peopleController.text = entry.people.toString();

    _persons.clear();
    if (entry.isSplitByItems) {
      // Copy, so editing the restored bill does not mutate the stored entry.
      for (final person in entry.persons) {
        _persons.add(
          Person(
            id: person.id,
            name: person.name,
            items: person.items
                .map(
                  (item) => PersonItem(
                    id: item.id,
                    label: item.label,
                    price: item.price,
                  ),
                )
                .toList(),
          ),
        );
      }
      _splitMode = SplitMode.byItems;
    } else {
      _splitMode = SplitMode.evenly;
    }
    notifyListeners();
  }

  void getRecommendedTip() async {
    if (_geminiAPI != null && _actualPosition.isNotEmpty) {
      _recommendedTip = await _geminiAPI!.generateContent(
        country: _actualPosition,
        type: "waiter",
      );
      _tipPercent = _recommendedTip!.avgVal.toInt();
      notifyListeners();
    }
  }

  void incrementTipPorcent() => setTipPercent(_tipPercent + 1);

  void decrementTipPorcent() => setTipPercent(_tipPercent - 1);
}
