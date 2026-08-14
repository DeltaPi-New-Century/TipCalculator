import 'dart:convert';
import 'dart:io';
import 'package:tip_calculator/schemas/currency.dart';
import 'package:tip_calculator/schemas/flag.dart';
import 'package:tip_calculator/service/network.dart';
import 'package:tip_calculator/schemas/country.dart';
import 'package:tip_calculator/schemas/language.dart';
import 'package:tip_calculator/service/translations_defaults.dart';

class DatabaseData {
  String _version;
  CountryData? _countryData;
  LanguagueData? _languageData;

  DatabaseData() : _version = "", _countryData = null, _languageData = null;
  String get version => _version;
  CountryData? get countryData => _countryData;
  String get countryName => _countryData != null ? _countryData!.country : "";
  LanguagueData? get languageData => _languageData;
  void setVersion(final String version) => _version = version;
  void setCountryData(final CountryData countryData) =>
      _countryData = countryData;
  void setLanguageData(final LanguagueData languageData) =>
      _languageData = languageData;

  static Future<dynamic> _readRemoteData(final String remote) async {
    final isConnected = await Network.checkConnection();
    if (isConnected) {
      try {
        final response = await Network.fetchData(remote);
        // Parse the JSON response and return a DatabaseData instance
        return response;
      } catch (e) {
        throw DatabaseRemoteException("Failed to fetch remote database: $e");
      }
    } else {
      throw ConnectionNetwork("No internet connection");
    }
  }

  static Future<dynamic> _readLocalData(final String local) async {
    final file = File(local);
    if (file.existsSync()) {
      final content = await file.readAsString();
      // Parse the JSON content and return a DatabaseData instance
      return content;
    } else {
      throw DatabaseLocalException("Local database file not found");
    }
  }

  static Future<dynamic> _writeLocalData(
    final String local,
    final dynamic data,
  ) async {
    final file = File(local);
    await file.writeAsString(data);
  }

  static Future<dynamic> _initDatabase(
    final String remote,
    final String local,
  ) async {
    try {
      final resultRemote = jsonDecode(await _readRemoteData(remote));
      try {
        final resultLocal = jsonDecode(await _readLocalData(local));
        if (resultLocal["version"].toString() !=
            resultRemote["version"].toString()) {
          await _writeLocalData(local, jsonEncode(resultRemote));
          return resultRemote;
        }
        return resultLocal;
      } on DatabaseLocalException {
        await _writeLocalData(local, jsonEncode(resultRemote));
        return resultRemote;
      }
    } on DatabaseRemoteException catch (_) {
      return null;
    } on ConnectionNetwork catch (_) {
      return null;
    }
  }

  static Future<DatabaseData> loadDatabase(
    final String remote,
    final String local,
    final String country,
    final String language,
  ) async {
    final result = await _initDatabase(remote, local);
    final DatabaseData dbData = DatabaseData();
    if (result != null) {
      dbData.setVersion(result["version"].toString());
      CountryData filteredCountry = CountryData.filterCountrys(
        result["database"],
        country,
      );
      dbData.setCountryData(filteredCountry);
      final filteredLanguage = LanguagueData.filterLanguages(
        result["languages"],
        language,
      );
      dbData.setLanguageData(filteredLanguage);
      return dbData;
    }
    dbData.setVersion("0.0");
    dbData.setCountryData(
      CountryData(
        continent: "",
        country: "",
        code: "",
        flag: FlagData(localpath: "", webpng: "", flag: ""),
        currency: CurrencyData(name: "\$", symbol: "\$"),
      ),
    );
    // Copied, because LanguagueData.setTranslation mutates the map it is given
    // and kDefaultTranslations is a shared const.
    dbData.setLanguageData(
      LanguagueData(translations: Map<String, String>.from(kDefaultTranslations)),
    );
    return dbData;
  }
}

class DatabaseLocalException implements Exception {
  final String message;
  DatabaseLocalException(this.message);
  @override
  String toString() => "LocalException: $message";
}

class DatabaseRemoteException implements Exception {
  final String message;
  DatabaseRemoteException(this.message);
  @override
  String toString() => "LocalException: $message";
}
