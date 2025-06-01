import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Caché para respuestas
  final Map<String, String> _responseCache = {};

  // API Key per al servei d'IA
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Preguntes freqüents amb les seves respostes
  final Map<String, String> _faqAnswers = {
    "Com reservar?": "🅿️ Primer, selecciona el carrer on vols reservar la plaça, escull el temps i confirma. Després, a la secció 'Reserves' podràs modificar la durada o finalitzar-la.",
    "Com cancel·lar una reserva?": "❌ Per cancel·lar una reserva, ves a la secció 'Reserves', selecciona la que vols cancel·lar i prem 'Cancel·lar reserva'.",
    "Quins mètodes de pagament s'accepten?": "💳 Actualment, només acceptem targetes de crèdit i dèbit.",
    "Què fer si algú ocupa la meva plaça?": "🚨 Si trobes la teva plaça ocupada, si us plau informa-ho des de l'app a la secció 'Ajuda' i el nostre equip t'assistirà el més aviat possible.",
    "Quant costa el servei?": "💰 El preu varia segons la zona i l'hora. Pots veure el preu exacte abans de confirmar la reserva.",
    "Puc ampliar el temps de reserva?": "⏰ Sí, pots ampliar el temps de la teva reserva des de la secció 'Reserves' sempre que la plaça continuï disponible.",
    "Com funcionen els punts?": "🎯 Guanyes punts cada vegada que utilitzes l'app. Podràs bescanviar-los per descomptes en futures reserves.",
    "Hi ha penalització per cancel·lació?": "ℹ️ No hi ha penalització si cancel·les amb més de 10 minuts d'antelació. Les cancel·lacions tardanes poden tenir un petit càrrec.",
  };

  // Respuestas de fallback cuando la API falla
  final List<String> _fallbackResponses = [
    "Entenc la teva pregunta. A ParkSwap, treballem per facilitar l'aparcament a tots els usuaris. Pots revisar les preguntes freqüents per més informació.",
    "Gràcies per la teva consulta. Actualment estem experimentant una alta demanda. Prova de nou més tard o consulta les preguntes freqüents.",
    "La teva pregunta és important per a nosaltres. Mentrestant, pots explorar la secció de reserves o consultar les preguntes freqüents.",
    "En aquest moment no puc processar la teva consulta. Si us plau, prova més tard o consulta les opcions disponibles a dalt.",
    "Estic aquí per ajudar-te amb ParkSwap. Si la teva pregunta és urgent, pots contactar amb el nostre equip de suport.",
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages().then((_) {
      // Esto ejecuta el scroll después de que los mensajes se cargan y la UI se renderiza
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });

    // Missatge de benvinguda
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Hola! Soc l'assistent de ParkSwap. En què et puc ajudar avui?",
            isUser: false,
          ),
        );
      });
      _saveMessages();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList('chat_messages') ?? [];

    setState(() {
      _messages.clear();
      for (final messageJson in messagesJson) {
        final messageMap = json.decode(messageJson);
        _messages.add(ChatMessage.fromJson(messageMap));
      }
    });
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = _messages.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList('chat_messages', messagesJson);
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();
    _saveMessages();

    // Revisar si la pregunta está en el FAQ
    String? faqAnswer;
    for (final question in _faqAnswers.keys) {
      if (text.toLowerCase().contains(question.toLowerCase()) ||
          _similarQuestion(text, question)) {
        faqAnswer = _faqAnswers[question];
        break;
      }
    }

    // Si está en el FAQ, usar esa respuesta
    if (faqAnswer != null) {
      _addBotResponse(faqAnswer);
      return;
    }

    // Revisar si tenemos una respuesta en caché
    if (_responseCache.containsKey(text.toLowerCase())) {
      _addBotResponse(_responseCache[text.toLowerCase()]!);
      return;
    }

    // Si no, intentar con la API
    try {
      final response = await _getAIResponse(text);

      // Guardar en caché
      _responseCache[text.toLowerCase()] = response;

      _addBotResponse(response);
    } catch (e) {
      print('Error en la API: $e');
      // Usar respuesta de fallback
      final fallback = _getFallbackResponse();
      _addBotResponse(fallback);
    }
  }

  void _addBotResponse(String text) {
    setState(() {
      _isLoading = false;
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _saveMessages();
    _scrollToBottom();
  }

  // Método para conseguir una respuesta alternativa cuando falla la API
  String _getFallbackResponse() {
    final random = Random();
    return _fallbackResponses[random.nextInt(_fallbackResponses.length)];
  }

  // Método para detectar preguntas similares
  bool _similarQuestion(String input, String question) {
    final inputWords = input.toLowerCase().split(' ');
    final questionWords = question.toLowerCase().split(' ');

    int matchCount = 0;
    for (final word in inputWords) {
      if (word.length > 3 && questionWords.contains(word)) {
        matchCount++;
      }
    }

    // Si al menos 2 palabras significativas coinciden
    return matchCount >= 2;
  }

  Future<String> _getAIResponse(String message) async {
    // Verificar caché primero
    if (_responseCache.containsKey(message)) {
      return _responseCache[message]!;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://parkswap.app',
          'X-Title': 'ParkSwap Assistant'
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-chat-v3-0324:free',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un asistente de ParkSwap, una aplicación para encontrar y reservar plazas de aparcamiento. SOLO debes responder,  y en catalán,  preguntas relacionadas con ParkSwap, su funcionamiento, reservas de estacionamiento, pago, historial, búsqueda de zonas, y otras funciones de la app. Si te preguntan sobre cualquier otro tema no relacionado con ParkSwap, responde: "Em sap greu, només et puc ajudar amb temes relacionats amb ParkSwap i estacionament. Tens algun dubte sobre com fer servir la nostra aplicació?"'
            },
            {'role': 'user', 'content': message}
          ],
          'temperature': 0.7,
          'max_tokens': 500
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiResponse = responseData['choices'][0]['message']['content'];

        // Guardar en caché
        _responseCache[message] = aiResponse;

        return aiResponse;
      } else {
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return 'Ho sento, s\'ha produït un error: ${response.statusCode}';
      }
    } catch (e) {
      print('Exception: $e');
      return 'Ho sento, s\'ha produït un error inesperat.';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleFAQSelection(String question) {
    final answer = _faqAnswers[question];
    if (answer != null) {
      setState(() {
        _messages.add(ChatMessage(text: question, isUser: true));
        _messages.add(ChatMessage(text: answer, isUser: false));
      });
      _saveMessages();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistent de ParkSwap'),
      ),
      body: Column(
        children: [
          // Sección de preguntas frecuentes
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _faqAnswers.keys.map((question) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ActionChip(
                    label: Text(question, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[300]!),
                    onPressed: () => _handleFAQSelection(question),
                  ),
                );
              }).toList(),
            ),
          ),
          // Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          // Indicador de carga
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Escrivint...'),
                ],
              ),
            ),
          // Campo de entrada
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escriu un missatge...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    // Añade estas propiedades:
                    textInputAction: TextInputAction.send,
                    onSubmitted: (text) => _sendMessage(),
                    // Si quieres mantener la capacidad de múltiples líneas con Shift+Enter:
                    maxLines: 5,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: message.isUser ? 64 : 0,
          right: message.isUser ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: MarkdownBody(
          data: message.text,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: message.isUser ? Colors.white : Colors.black,
            ),
            strong: TextStyle(
              color: message.isUser ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
