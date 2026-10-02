import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LlmService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];

  Future<Map<String, dynamic>?> extractTransactionData(String text) async {
    if (_apiKey == null || _apiKey.isEmpty) {
      // Fallback offline regex/rule-based parser could go here
      return _fallbackParser(text);
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final systemPrompt = '''
You are a highly intelligent financial assistant. Your task is to extract transaction details from user input and format it as a JSON object.

Extract the following information:
- amount: (float) the amount of money
- category: (string) a short category name like "Food", "Transport", "Salary", "Shopping", etc.
- note: (string) the original item or description
- type: (string) either "expense" or "income"
- date: (string) ISO 8601 date string. If the user doesn't specify a date, use the current time.

User input could be like: "Lunch with colleagues 650", "Coffee 200 rubles", "Got my salary 5000".

Return ONLY a valid JSON object in the following format, with no markdown formatting or extra text:
{
  "amount": float,
  "category": "string",
  "note": "string",
  "type": "expense" | "income",
  "date": "ISOString"
}
''';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Input: "$text"\nCurrent Date: ${DateTime.now().toIso8601String()}'}
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        print('Error from LLM API: ${response.body}');
        return _fallbackParser(text);
      }
    } catch (e) {
      print('Exception during LLM parsing: $e');
      return _fallbackParser(text);
    }
  }

  Map<String, dynamic>? _fallbackParser(String text) {
    // A simple regex-based fallback if LLM is unavailable
    final regex = RegExp(r'([\d\.]+)', multiLine: true);
    final match = regex.firstMatch(text);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!) ?? 0.0;
      final type = text.toLowerCase().contains('salary') || text.toLowerCase().contains('income') ? 'income' : 'expense';
      return {
        'amount': amount,
        'category': 'General',
        'note': text,
        'type': type,
        'date': DateTime.now().toIso8601String(),
      };
    }
    return null; // Could not parse
  }
}
