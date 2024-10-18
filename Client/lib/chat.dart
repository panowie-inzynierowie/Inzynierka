import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/classes/chat.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class ChatDialog extends StatefulWidget {
  const ChatDialog({Key? key}) : super(key: key);

  @override
  ChatDialogState createState() => ChatDialogState();
}

class ChatDialogState extends State<ChatDialog> {
  List<ChatMessage> messages = [];
  final TextEditingController fieldText = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    messages = context.watch<AppState>().chatMessages;
  }

  void _startListening() async {
    setState(() {
      _listening = true;
    });
    await _speechToText.listen(onResult: _onSpeechResult);
  }

  void _stopListening() async {
    setState(() {
      _listening = false;
    });
    await _speechToText.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    fieldText.value = TextEditingValue(text: result.recognizedWords);
  }

  // Send message to Django backend and get response from ChatGPT
  Future<void> _sendMessage(String message) async {
    final url = Uri.parse('${dotenv.env['API_URL']}/api/chat/');

    setState(() {
      messages.add(ChatMessage(author: Author.user, content: message));
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatResponse = data['response'];

        // Add the response from the LLM (ChatGPT's reply) to the chat
        setState(() {
          messages.add(ChatMessage(author: Author.llm, content: chatResponse));  // Changed to Author.llm
        });
      } else {
        throw Exception('Failed to load response');
      }
    } catch (e) {
      // Handle any errors
      setState(() {
        messages.add(ChatMessage(author: Author.llm, content: "Error: $e"));  // Changed to Author.llm
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width * 0.7;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message.author == Author.user;

                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueAccent.withOpacity(0.7)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isUser ? 12 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser
                              ? context.watch<AppState>().username
                              : 'System',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: fieldText,
                  decoration: InputDecoration(
                    labelText: 'New message',
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    _sendMessage(value);  // Send message to backend
                    fieldText.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _listening ? Icons.mic_off : Icons.mic,
                  color: _listening ? Colors.red : Colors.blueAccent,
                  size: 28,
                ),
                onPressed: () {
                  if (_speechToText.isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
