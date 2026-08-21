import 'dart:convert';
import 'package:tip_calculator/service/config.dart';
import 'package:tip_calculator/service/network.dart';

class Geolocation {
  static String ipApiUrl = Config.ipApiUrl;

  /// Fetches the current location of the user based on their IP address.
  /// Returns the location code (like country code) for the specified key.
  /// @param The key to extract from the location data (e.g., "country", "countryCode").
  static Future<String> getCurrentLocation(final String key) async {
    return Network.fetchData(Geolocation.ipApiUrl)
        .then((response) {
          final locationCode = jsonDecode(response);
          return locationCode[key] as String;
        })
        .catchError((error) {
          throw Exception('Error fetching location: $error');
        });
  }
}
