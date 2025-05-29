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
    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    setState(() => _messages.insert(0, userMessage));

    try {
      final botReply = await _chatService.sendMessage(message.text, null, null);
      _addBotMessage(botReply);
    } catch (e) {
      _addBotMessage("Ho sento, va passar un error en processar la teva sol·licitud.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assistent de ParkSwap")),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        theme: const DefaultChatTheme(
          inputBackgroundColor: Colors.green,
          inputTextColor: Colors.white,
        ),
      ),
    );
  }
}