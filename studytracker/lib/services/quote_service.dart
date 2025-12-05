import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteService {
  static Future<Map<String, String>> getRandomQuote() async {
final url = Uri.parse('https://motivational-spark-api.vercel.app/api/quotes/random');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'quote': data['quote'],
        'author': data['author'],
      };
    } else {
      throw Exception("Failed to fetch quote");
    }
  }
}
