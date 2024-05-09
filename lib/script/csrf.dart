import 'dart:convert';
import 'package:http/http.dart' as http;

class Getcsrf {
  static get_csrf() async {
    final url = Uri.parse("http://localhost:8000/csrf/");
    final response = await http.get(url);

    try {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["csrf"];
      } else {
        return "error";
      }
    } catch (e) {
      return "error";
    }
  }
}
