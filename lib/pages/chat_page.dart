import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';

import '../services/chat_services.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<types.Message> _messages = [];
  final types.User _user = const types.User(id: 'user');
  final types.User _bot = const types.User(id: 'bot');
  final _chatService = ChatService();

  final Map<String, String> _faqAnswers = {
    "Com reservar?": "🅿️ Primer, selecciona el carrer on vols reservar la plaça, escull el temps i confirma. Després, a la secció 'Reserves' podràs modificar la durada o finalitzar-la.",
    "Com cancel·lar una reserva?": "❌ Per cancel·lar una reserva, ves a la secció 'Reserves', selecciona la que vols cancel·lar i prem 'Cancel·lar reserva'.",
    "Quins mètodes de pagament s’accepten?": "💳 Actualmente, només acceptem targetes de crèdit i dèbit.",
    "Què fer si algú ocupa la meva plaça?": "🚨 Si trobes la teva plaça ocupada, si us plau informa-ho des de l'app a la secció 'Ajuda' i el nostre equip t'assistirà el més aviat possible.",
  };

  @override
  void initState() {
    super.initState();
    _addBotMessage("👋 Hola! Sóc el teu assistent de ParkSwap. En què et puc ajudar?");
  }

  void _addBotMessage(String text) {
    final message = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );
    setState(() => _messages.insert(0, message));
  }

  void _handleSendPressed(types.PartialText message) async {
    final userText = message.text.trim();

    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: userText,
    );
    setState(() => _messages.insert(0, userMessage));

    // Comprova si és una pregunta freqüent
    if (_faqAnswers.containsKey(userText)) {
      _addBotMessage(_faqAnswers[userText]!);
      return;
    }

    try {
      final botReply = await _chatService.sendMessage(userText, null, null);
      _addBotMessage(botReply);
    } catch (e) {
      _addBotMessage("⚠️ Ho sento, hi ha hagut un problema amb el servei.");
    }
  }

  void _handleFAQOptionSelected(String question) {
    _handleSendPressed(types.PartialText(text: question));
  }

  Widget _buildFAQButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _faqAnswers.keys.map((faq) {
        return ElevatedButton(
          onPressed: () => _handleFAQOptionSelected(faq),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(faq),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assistent de ParkSwap")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildFAQButtons(),
          ),
          Expanded(
            child: Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _user,
              theme: const DefaultChatTheme(
                inputBackgroundColor: Colors.green,
                inputTextColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
