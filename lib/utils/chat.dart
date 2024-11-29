import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:projects/utils/globals.dart' as globals;

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final WebSocketChannel _channel = WebSocketChannel.connect(
    Uri.parse(globals.wsURL), // Replace with your WebSocket server URL
  );
  List<types.Message> _messages = [];
  bool _isLoading = false;

  // Function to send a message to the WebSocket server
  void _sendMessage(String message) {
    final prompt = {
      "prompt": message,
    };
    _channel.sink.add(json.encode(prompt));
    setState(() {
      _isLoading = true;
    });
  }

  // Function to handle the incoming message
  void _handleMessage(String message) {
    final response = json.decode(message);
    if (response.containsKey('response')) {
      final botMessage = types.TextMessage(
        author: types.User(id: 'bot', firstName: 'AI'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        text: response['response'],
        id: DateTime.now().toIso8601String(), // Unique ID
      );
      setState(() {
        _messages.insert(0, botMessage); // Add at the top
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Listen for incoming WebSocket messages
    _channel.stream.listen((message) {
      _handleMessage(message);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _channel.sink.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with AI"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Chat(
              messages: _messages,
              onSendPressed: (types.PartialText message) {
                final userMessage = types.TextMessage(
                  author: const types.User(id: 'user', firstName: 'You'),
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  text: message.text,
                  id: DateTime.now().toIso8601String(), // Unique ID
                );
                setState(() {
                  _messages.insert(0, userMessage); // Add at the top
                });

                // Send the message to the WebSocket server
                _sendMessage(message.text);
              },
              user: const types.User(id: 'user'),
              theme: DefaultChatTheme(
                inputBackgroundColor: Colors.white,
                inputTextColor: Colors.black,
                primaryColor: Colors.blue,
                secondaryColor: Colors.grey[200]!,
                inputTextStyle: TextStyle(fontSize: 18),
                inputPadding: const EdgeInsets.all(15),

                inputMargin: EdgeInsets.all(10), // Better padding
                userAvatarNameColors: [Colors.blue, Colors.green],
                messageInsetsVertical: 10, // Vertical padding for messages
                inputContainerDecoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                messageInsetsHorizontal: 16,
              ),
              showUserAvatars: true,
              showUserNames: true,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
