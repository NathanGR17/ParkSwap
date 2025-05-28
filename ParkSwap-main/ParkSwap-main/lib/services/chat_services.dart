import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String _apiKey = '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';

  Future<String> sendMessage(String message, String location, String history) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
            'Eres un asistente que recomienda horarios y lugares para reservar aparcamiento basándote en la localización y el historial del usuario.'
          },
          {
            'role': 'user',
            'content':
            'Mi historial de reservas es:\n$history\nUbicación actual: $location\n$message'
          },
        ],
        'temperature': 0.7,
      }),
    );

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}
