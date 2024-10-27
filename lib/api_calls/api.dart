import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  static Future<dynamic> getRequest(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        String jsonData = response.body;
        var decodeData = jsonDecode(jsonData);
        return decodeData;
      } else {
        return 'failed';
      }
    } catch (e) {
      return 'failed';
    }
  }
}
