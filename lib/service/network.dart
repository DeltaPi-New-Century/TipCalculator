import 'package:http/http.dart' as http;

class Network {
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse("https://www.google.com"))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fecth data from a given URL.
  static Future<String> fetchData(final String url) {
    return http
        .get(Uri.parse(url))
        .then((response) {
          if (response.statusCode == 200) {
            return response.body;
          } else {
            throw Exception('Failed to load data');
          }
        })
        .catchError((error) {
          throw Exception('Error fetching data: $error');
        });
  }

  // static Future<String> fetchData(
  //   final String url,
  //   final Map<String, String> header,
  //   final Map<String, dynamic> body,
  // ) {
  //   return http
  //       .get(Uri.parse(url), headers: header)
  //       .then((response) {
  //         if (response.statusCode == 200) {
  //           return response.body;
  //         } else {
  //           throw Exception('Failed to load data');
  //         }
  //       })
  //       .catchError((error) {
  //         throw Exception('Error fetching data: $error');
  //       });
  // }

}

class ConnectionNetwork implements Exception {
  final String message;
  ConnectionNetwork(this.message);
  @override
  String toString() => 'Network: $message';
}
