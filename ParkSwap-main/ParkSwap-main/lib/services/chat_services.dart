import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String _apiKey = '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'; // 🔐 Sustituye con tu clave real

  Future<String> sendMessage(String message, dynamic location, dynamic history) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": "Eres un asistente que ayuda con estacionamientos."},
          {"role": "user", "content": message}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'];
      return reply.trim();
    } else {
      return "Lo siento, hubo un problema con el servicio de IA.";
    }
  }
}
